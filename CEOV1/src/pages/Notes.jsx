import React, { useState, useEffect, useRef } from 'react';
import { Link } from 'react-router-dom';
import { createPageUrl } from '../utils';
import { base44 } from '@/api/base44Client';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { ArrowLeft, Plus, Search, Trash2, ChevronRight, ChevronDown } from 'lucide-react';
import { format } from 'date-fns';
import { Textarea } from '@/components/ui/textarea';

export default function Notes() {
  const [selectedTag, setSelectedTag] = useState('all');
  const [selectedNote, setSelectedNote] = useState(null);
  const [searchQuery, setSearchQuery] = useState('');
  const [showSearch, setShowSearch] = useState(false);
  const [expandedTags, setExpandedTags] = useState(new Set(['all', 'recent']));
  const editorRef = useRef(null);
  const saveTimeoutRef = useRef(null);
  const queryClient = useQueryClient();

  const { data: notes = [] } = useQuery({
    queryKey: ['notes'],
    queryFn: () => base44.entities.Note.list('-updated_date')
  });

  const createNoteMutation = useMutation({
    mutationFn: (data) => base44.entities.Note.create(data),
    onSuccess: (newNote) => {
      queryClient.invalidateQueries(['notes']);
      setSelectedNote(newNote);
    }
  });

  const updateNoteMutation = useMutation({
    mutationFn: ({ id, data }) => base44.entities.Note.update(id, data),
    onSuccess: () => {
      queryClient.invalidateQueries(['notes']);
    },
    onMutate: async ({ id, data }) => {
      await queryClient.cancelQueries(['notes']);
      const previousNotes = queryClient.getQueryData(['notes']);
      queryClient.setQueryData(['notes'], old => 
        old.map(n => n.id === id ? { ...n, ...data } : n)
      );
      return { previousNotes };
    },
    onError: (err, variables, context) => {
      queryClient.setQueryData(['notes'], context.previousNotes);
    }
  });

  const deleteNoteMutation = useMutation({
    mutationFn: (id) => base44.entities.Note.delete(id),
    onSuccess: () => {
      queryClient.invalidateQueries(['notes']);
      setSelectedNote(null);
    }
  });

  // Extract tags from note content
  const extractTags = (content) => {
    if (!content) return [];
    const tagRegex = /#[\w\u00C0-\u024F\u1E00-\u1EFF\/]+/g;
    const matches = content.match(tagRegex) || [];
    return [...new Set(matches.map(tag => tag.slice(1)))]; // Remove #
  };

  // Helper function to avoid duplication
  const extractTagsFromContent = (content) => {
    if (!content) return [];
    const tagRegex = /#[\w\u00C0-\u024F\u1E00-\u1EFF\/]+/g;
    const matches = content.match(tagRegex) || [];
    return [...new Set(matches.map(tag => tag.slice(1)))]; // Remove #
  };

  // Build tag hierarchy
  const buildTagHierarchy = () => {
    const allTags = new Set();
    notes.forEach(note => {
      const tags = extractTags(note.content);
      tags.forEach(tag => allTags.add(tag));
    });

    const hierarchy = {};
    allTags.forEach(tag => {
      const parts = tag.split('/');
      let current = hierarchy;
      parts.forEach((part, index) => {
        const fullPath = parts.slice(0, index + 1).join('/');
        if (!current[part]) {
          current[part] = { children: {}, fullPath, count: 0 };
        }
        current = current[part].children;
      });
    });

    // Count notes per tag
    const countNotes = (tag) => {
      return notes.filter(note => {
        const noteTags = extractTags(note.content);
        return noteTags.some(t => t === tag || t.startsWith(tag + '/'));
      }).length;
    };

    const addCounts = (obj) => {
      Object.keys(obj).forEach(key => {
        obj[key].count = countNotes(obj[key].fullPath);
        if (Object.keys(obj[key].children).length > 0) {
          addCounts(obj[key].children);
        }
      });
    };
    addCounts(hierarchy);

    return hierarchy;
  };

  const tagHierarchy = buildTagHierarchy();

  // Filter notes by selected tag and search
  const filteredNotes = notes.filter(note => {
    const noteTags = extractTags(note.content);
    const matchesTag = selectedTag === 'all' || 
      noteTags.some(t => t === selectedTag || t.startsWith(selectedTag + '/'));
    
    if (!matchesTag) return false;

    if (searchQuery.trim()) {
      const query = searchQuery.toLowerCase();
      return note.content.toLowerCase().includes(query);
    }
    
    return true;
  });

  // Get note title (first line)
  const getNoteTitle = (content) => {
    if (!content) return 'Untitled';
    const firstLine = content.split('\n')[0].trim();
    return firstLine.replace(/^#+\s*/, '').slice(0, 60) || 'Untitled';
  };

  // Get note preview
  const getNotePreview = (content) => {
    if (!content) return '';
    const lines = content.split('\n');
    const preview = lines.slice(1).join(' ').trim();
    return preview.slice(0, 100);
  };

  // Handle content change with auto-save
  const handleContentChange = (content) => {
    if (!selectedNote) return;

    setSelectedNote({ ...selectedNote, content });

    if (saveTimeoutRef.current) {
      clearTimeout(saveTimeoutRef.current);
    }

    saveTimeoutRef.current = setTimeout(() => {
      updateNoteMutation.mutate({
        id: selectedNote.id,
        data: { content }
      });
    }, 500);
  };

  // Create new note
  const handleNewNote = () => {
    if (createNoteMutation.isPending) return;
    
    createNoteMutation.mutate({
      title: 'Untitled',
      content: '',
      tags: [],
      color: 'default',
      pinned: false,
      archived: false
    });
  };

  // Delete note with confirmation
  const handleDeleteNote = () => {
    if (!selectedNote) return;
    if (window.confirm('Delete this note?')) {
      deleteNoteMutation.mutate(selectedNote.id);
    }
  };

  // Toggle tag expansion
  const toggleTag = (tag) => {
    const newExpanded = new Set(expandedTags);
    if (newExpanded.has(tag)) {
      newExpanded.delete(tag);
    } else {
      newExpanded.add(tag);
    }
    setExpandedTags(newExpanded);
  };

  // Get notes for a specific tag
  const getNotesForTag = (tagPath) => {
    return notes.filter(note => {
      const noteTags = extractTags(note.content);
      return noteTags.some(t => t === tagPath || t.startsWith(tagPath + '/'));
    });
  };

  // Render tag tree with notes
  const renderTagTree = (obj, level = 0) => {
    return Object.keys(obj).sort().map(key => {
      const tag = obj[key];
      const hasChildren = Object.keys(tag.children).length > 0;
      const isExpanded = expandedTags.has(tag.fullPath);
      const isSelected = selectedTag === tag.fullPath;
      const tagNotes = getNotesForTag(tag.fullPath);
      const hasMultipleNotes = tagNotes.length > 1;

      return (
        <div key={tag.fullPath} className="mb-1">
          <button
            onClick={() => {
              setSelectedTag(tag.fullPath);
              if (hasChildren || hasMultipleNotes) {
                toggleTag(tag.fullPath);
              }
              // Si une seule note, l'ouvrir directement
              if (!hasChildren && tagNotes.length === 1) {
                setSelectedNote(tagNotes[0]);
              }
            }}
            className={`w-full flex items-center gap-1.5 px-2 py-2.5 rounded-xl text-xs font-medium transition-all duration-150 relative group overflow-hidden ${
              isSelected 
                ? 'bg-gradient-to-br from-indigo-950/80 to-purple-950/80 text-white border-2 border-indigo-600/50 shadow-[0_4px_20px_rgba(99,102,241,0.3),inset_0_1px_0_rgba(255,255,255,0.05)]' 
                : 'text-zinc-400 hover:bg-zinc-900/50 hover:text-zinc-200 border-2 border-transparent'
            }`}
            style={{ marginLeft: `${level * 8}px` }}
          >
            {isSelected && (
              <div className="absolute inset-0 bg-gradient-to-br from-indigo-500/10 to-purple-500/10 pointer-events-none" />
            )}
            {(hasChildren || hasMultipleNotes) && (
              <span className={`w-3 h-3 flex items-center justify-center transition-transform relative flex-shrink-0 ${isExpanded ? '' : '-rotate-90'}`}>
                <ChevronDown className="w-2.5 h-2.5" />
              </span>
            )}
            {!hasChildren && !hasMultipleNotes && <span className="w-3 flex-shrink-0" />}
            <span className="flex-1 text-left truncate relative block min-w-0">{key}</span>
          </button>
          {hasChildren && isExpanded && renderTagTree(tag.children, level + 1)}
          {!hasChildren && hasMultipleNotes && isExpanded && (
            <div className="ml-2 mt-1">
              {tagNotes.map(note => {
                const noteTitle = getNoteTitle(note.content);
                const isNoteSelected = selectedNote?.id === note.id;
                return (
                  <button
                    key={note.id}
                    onClick={() => setSelectedNote(note)}
                    className={`w-full flex items-center gap-1.5 px-2 py-1.5 rounded-lg text-[10px] transition-all duration-150 mb-0.5 ${
                      isNoteSelected
                        ? 'bg-indigo-950/60 text-indigo-200 border border-indigo-700/40'
                        : 'text-zinc-500 hover:bg-zinc-900/40 hover:text-zinc-300'
                    }`}
                    style={{ marginLeft: `${(level + 1) * 8}px` }}
                  >
                    <span className="w-2 flex-shrink-0" />
                    <span className="flex-1 text-left truncate block min-w-0">{noteTitle}</span>
                  </button>
                );
              })}
            </div>
          )}
        </div>
      );
    });
  };

  // Auto-focus editor when note is selected
  useEffect(() => {
    if (selectedNote && editorRef.current) {
      editorRef.current.focus();
    }
  }, [selectedNote]);

  // Get 5 most recent notes
  const recentNotes = [...notes].slice(0, 5);

  return (
    <div className="min-h-screen bg-black text-white pt-16 relative overflow-hidden">
      {/* Texture */}
      <div className="fixed inset-0 pointer-events-none opacity-[0.02]" style={{
        backgroundImage: `url("data:image/svg+xml,%3Csvg viewBox='0 0 400 400' xmlns='http://www.w3.org/2000/svg'%3E%3Cfilter id='noiseFilter'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='3' numOctaves='5' stitchTiles='stitch'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23noiseFilter)'/%3E%3C/svg%3E")`,
        backgroundRepeat: 'repeat',
        backgroundSize: '200px 200px'
      }} />

      {/* Header */}
      <div className="fixed top-0 left-0 right-0 h-16 bg-black/95 backdrop-blur-2xl border-b-2 border-zinc-800/80 shadow-[0_8px_32px_rgba(0,0,0,0.8)] z-50 flex items-center justify-between px-4">
        <Link to={createPageUrl('Home')} className="w-11 h-11 flex items-center justify-center rounded-2xl bg-gradient-to-br from-zinc-900/90 to-zinc-950/90 border-2 border-zinc-800/60 hover:border-zinc-700/60 active:scale-95 transition-all duration-150 shadow-[0_4px_16px_rgba(0,0,0,0.6),inset_0_1px_0_rgba(255,255,255,0.03)]">
          <ArrowLeft className="w-4 h-4 text-zinc-400" />
        </Link>
        
        <div className="text-base font-black tracking-tight bg-gradient-to-r from-indigo-400 via-purple-400 to-indigo-500 bg-clip-text text-transparent drop-shadow-[0_2px_8px_rgba(99,102,241,0.3)]">
          Notes
        </div>

        <div className="flex items-center gap-2">
          {showSearch && (
            <input
              type="text"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder="Search..."
              className="w-40 h-11 px-3 bg-zinc-900/90 backdrop-blur-sm border-2 border-zinc-800/90 rounded-2xl text-sm text-white placeholder:text-zinc-600 focus:outline-none focus:border-indigo-700/60 shadow-[inset_0_2px_12px_rgba(0,0,0,0.4)] transition-all"
              autoFocus
              onBlur={() => !searchQuery && setShowSearch(false)}
            />
          )}
          {!showSearch && (
            <button
              onClick={() => setShowSearch(true)}
              className="w-11 h-11 flex items-center justify-center rounded-2xl bg-gradient-to-br from-zinc-900/90 to-zinc-950/90 border-2 border-zinc-800/60 hover:border-indigo-700/60 active:scale-95 transition-all duration-150 shadow-[0_4px_16px_rgba(0,0,0,0.6),inset_0_1px_0_rgba(255,255,255,0.03)]"
            >
              <Search className="w-4 h-4 text-zinc-400" />
            </button>
          )}
          <button
            onClick={handleNewNote}
            disabled={createNoteMutation.isPending}
            className="w-11 h-11 flex items-center justify-center rounded-2xl bg-gradient-to-br from-indigo-600 via-purple-600 to-indigo-700 border-2 border-indigo-500/40 hover:from-indigo-500 hover:via-purple-500 hover:to-indigo-600 active:scale-95 transition-all duration-150 shadow-[0_6px_24px_rgba(99,102,241,0.5),inset_0_2px_0_rgba(255,255,255,0.2)] hover:shadow-[0_8px_32px_rgba(99,102,241,0.7)] disabled:opacity-50 disabled:cursor-not-allowed"
          >
            <Plus className="w-5 h-5 text-white drop-shadow-[0_2px_4px_rgba(0,0,0,0.4)]" />
          </button>
        </div>
      </div>

      {/* 2 Column Layout */}
      <div className="flex h-[calc(100vh-4rem)]">
        {/* Left Sidebar - Tags + Recent Notes */}
        <div className="w-28 sm:w-64 md:w-80 border-r-2 border-zinc-900/90 bg-gradient-to-b from-zinc-950/60 via-zinc-950/50 to-zinc-950/60 backdrop-blur-xl overflow-y-auto shadow-[inset_-8px_0_24px_rgba(0,0,0,0.4)]">
          {/* Recent Notes Section - Collapsible */}
          <div className="p-3 border-b-2 border-zinc-900/80">
            <button
              onClick={() => setExpandedTags(prev => {
                const newSet = new Set(prev);
                if (newSet.has('recent')) {
                  newSet.delete('recent');
                } else {
                  newSet.add('recent');
                }
                return newSet;
              })}
              className="w-full flex items-center justify-between mb-2 px-1"
            >
              <div className="text-xs font-black uppercase tracking-wider text-zinc-500">
                Recent
              </div>
              <ChevronDown className={`w-3 h-3 text-zinc-500 transition-transform ${expandedTags.has('recent') ? '' : '-rotate-90'}`} />
            </button>

            {expandedTags.has('recent') && (
              <div className="space-y-1">
                {recentNotes.map(note => {
                  const isSelected = selectedNote?.id === note.id;
                  return (
                    <button
                      key={note.id}
                      onClick={() => setSelectedNote(note)}
                      className={`w-full p-2 rounded-xl transition-all duration-150 text-left relative group overflow-hidden ${
                        isSelected 
                          ? 'bg-gradient-to-br from-indigo-950/80 to-purple-950/80 border-2 border-indigo-600/50 shadow-[0_4px_20px_rgba(99,102,241,0.3),inset_0_1px_0_rgba(255,255,255,0.05)]' 
                          : 'bg-zinc-900/40 border-2 border-zinc-800/40 hover:border-zinc-700/50 hover:bg-zinc-900/60'
                      }`}
                    >
                      {isSelected && (
                        <div className="absolute inset-0 bg-gradient-to-br from-indigo-500/10 to-purple-500/10 pointer-events-none" />
                      )}
                      <div className="relative">
                        <div className={`font-bold text-xs mb-0.5 truncate ${isSelected ? 'text-white' : 'text-zinc-300 group-hover:text-white'}`}>
                          {getNoteTitle(note.content)}
                        </div>
                        <div className={`text-[9px] ${isSelected ? 'text-indigo-400' : 'text-zinc-600'}`}>
                          {format(new Date(note.updated_date), 'MMM d')}
                        </div>
                      </div>
                    </button>
                  );
                })}
                {recentNotes.length === 0 && (
                  <div className="text-center py-4 text-zinc-700 text-xs">
                    No recent notes
                  </div>
                )}
              </div>
            )}
          </div>

          {/* Tags Section */}
          <div className="p-2">
            <button
              onClick={() => setSelectedTag('all')}
              className={`w-full flex items-center justify-between px-2 py-2.5 rounded-xl text-xs font-semibold transition-all duration-150 relative group overflow-hidden ${
                selectedTag === 'all' 
                  ? 'bg-gradient-to-br from-indigo-950/80 to-purple-950/80 text-white border-2 border-indigo-600/50 shadow-[0_4px_20px_rgba(99,102,241,0.3),inset_0_1px_0_rgba(255,255,255,0.05)]' 
                  : 'text-zinc-400 hover:bg-zinc-900/50 hover:text-zinc-200 border-2 border-transparent'
              }`}
            >
              {selectedTag === 'all' && (
                <div className="absolute inset-0 bg-gradient-to-br from-indigo-500/10 to-purple-500/10 pointer-events-none" />
              )}
              <span className="relative truncate block min-w-0 flex-1 text-left">All Notes</span>
              <span className={`text-[10px] px-2 py-0.5 rounded-full relative flex-shrink-0 ml-1 ${
                selectedTag === 'all'
                  ? 'bg-indigo-900/60 text-indigo-300 shadow-[inset_0_2px_4px_rgba(0,0,0,0.4)]'
                  : 'bg-zinc-800/50 text-zinc-600'
              }`}>
                {notes.length}
              </span>
            </button>
            <div className="mt-1">
              {renderTagTree(tagHierarchy)}
            </div>
          </div>
        </div>

        {/* Right Column - Editor */}
        <div className="flex-1 overflow-y-auto bg-gradient-to-br from-black/50 via-zinc-950/30 to-black/50">
          {selectedNote ? (
            <div className="max-w-2xl mx-auto p-6">
              <div className="flex justify-end mb-4">
                <button
                  onClick={handleDeleteNote}
                  className="p-3 rounded-2xl bg-gradient-to-br from-zinc-900/90 to-zinc-950/90 border-2 border-zinc-800/60 hover:border-red-800/60 hover:from-red-950/40 hover:to-red-950/40 active:scale-95 transition-all duration-150 text-zinc-500 hover:text-red-400 shadow-[0_4px_16px_rgba(0,0,0,0.6),inset_0_1px_0_rgba(255,255,255,0.03)]"
                >
                  <Trash2 className="w-4 h-4" />
                </button>
              </div>
              <Textarea
                ref={editorRef}
                value={selectedNote.content || ''}
                onChange={(e) => handleContentChange(e.target.value)}
                placeholder="Start writing... Use #tag to organize"
                className="w-full min-h-[calc(100vh-12rem)] bg-transparent border-none focus:ring-0 resize-none text-sm leading-loose text-zinc-100 p-0 placeholder:text-zinc-700/60 font-light tracking-wide caret-zinc-400"
                style={{ outline: 'none', boxShadow: 'none', caretColor: '#9ca3af' }}
              />
            </div>
          ) : (
            <div className="h-full flex flex-col items-center justify-center text-center">
              <div className="text-zinc-800 text-7xl mb-4">✏️</div>
              <div className="text-zinc-600 text-sm font-medium">Select a note or create a new one</div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}