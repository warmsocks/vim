" Test using builtin functions in the Vim9 script language.

source check.vim
source vim9.vim

" Test for passing too many or too few arguments to builtin functions
func Test_internalfunc_arg_error()
  let l =<< trim END
    def! FArgErr(): float
      return ceil(1.1, 2)
    enddef
    defcompile
  END
  call writefile(l, 'Xinvalidarg')
  call assert_fails('so Xinvalidarg', 'E118:', '', 1, 'FArgErr')
  let l =<< trim END
    def! FArgErr(): float
      return ceil()
    enddef
    defcompile
  END
  call writefile(l, 'Xinvalidarg')
  call assert_fails('so Xinvalidarg', 'E119:', '', 1, 'FArgErr')
  call delete('Xinvalidarg')
endfunc

" Test for builtin functions returning different types
func Test_InternalFuncRetType()
  let lines =<< trim END
    def RetFloat(): float
      return ceil(1.456)
    enddef

    def RetListAny(): list<any>
      return items({k: 'v'})
    enddef

    def RetListString(): list<string>
      return split('a:b:c', ':')
    enddef

    def RetListDictAny(): list<dict<any>>
      return getbufinfo()
    enddef

    def RetDictNumber(): dict<number>
      return wordcount()
    enddef

    def RetDictString(): dict<string>
      return environ()
    enddef
  END
  call writefile(lines, 'Xscript')
  source Xscript

  call RetFloat()->assert_equal(2.0)
  call RetListAny()->assert_equal([['k', 'v']])
  call RetListString()->assert_equal(['a', 'b', 'c'])
  call RetListDictAny()->assert_notequal([])
  call RetDictNumber()->assert_notequal({})
  call RetDictString()->assert_notequal({})
  call delete('Xscript')
endfunc

def Test_abs()
  assert_equal(0, abs(0))
  assert_equal(2, abs(-2))
  assert_equal(3, abs(3))
  CheckDefFailure(['abs("text")'], 'E1013: Argument 1: type mismatch, expected number but got string', 1)
  if has('float')
    assert_equal(0, abs(0))
    assert_equal(2.0, abs(-2.0))
    assert_equal(3.0, abs(3.0))
  endif
enddef

def Test_add_list()
  var l: list<number>  # defaults to empty list
  add(l, 9)
  assert_equal([9], l)

  var lines =<< trim END
      var l: list<number>
      add(l, "x")
  END
  CheckDefFailure(lines, 'E1012:', 2)

  lines =<< trim END
      add(test_null_list(), 123)
  END
  CheckDefExecAndScriptFailure(lines, 'E1130:', 1)

  lines =<< trim END
      var l: list<number> = test_null_list()
      add(l, 123)
  END
  CheckDefExecFailure(lines, 'E1130:', 2)

  # Getting variable with NULL list allocates a new list at script level
  lines =<< trim END
      vim9script
      var l: list<number> = test_null_list()
      add(l, 123)
  END
  CheckScriptSuccess(lines)

  lines =<< trim END
      vim9script
      var l: list<string> = ['a']
      l->add(123)
  END
  CheckScriptFailure(lines, 'E1012: Type mismatch; expected string but got number', 3)

  lines =<< trim END
      vim9script
      var l: list<string>
      l->add(123)
  END
  CheckScriptFailure(lines, 'E1012: Type mismatch; expected string but got number', 3)
enddef

def Test_add_blob()
  var b1: blob = 0z12
  add(b1, 0x34)
  assert_equal(0z1234, b1)

  var b2: blob # defaults to empty blob
  add(b2, 0x67)
  assert_equal(0z67, b2)

  var lines =<< trim END
      var b: blob
      add(b, "x")
  END
  CheckDefFailure(lines, 'E1012:', 2)

  lines =<< trim END
      add(test_null_blob(), 123)
  END
  CheckDefExecAndScriptFailure(lines, 'E1131:', 1)

  lines =<< trim END
      var b: blob = test_null_blob()
      add(b, 123)
  END
  CheckDefExecFailure(lines, 'E1131:', 2)

  # Getting variable with NULL blob allocates a new blob at script level
  lines =<< trim END
      vim9script
      var b: blob = test_null_blob()
      add(b, 123)
  END
  CheckScriptSuccess(lines)
enddef

def Test_and()
  CheckDefAndScriptFailure2(['and("x", 0x2)'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1030: Using a String as a Number')
  CheckDefAndScriptFailure2(['and(0x1, "x")'], 'E1013: Argument 2: type mismatch, expected number but got string', 'E1030: Using a String as a Number')
enddef

def Test_append()
  new
  setline(1, range(3))
  var res1: number = append(1, 'one')
  assert_equal(0, res1)
  var res2: bool = append(3, 'two')
  assert_equal(false, res2)
  assert_equal(['0', 'one', '1', 'two', '2'], getline(1, 6))

  append(0, 'zero')
  assert_equal('zero', getline(1))
  bwipe!
enddef

def Test_argc()
  CheckDefFailure(['argc("x")'], 'E1013: Argument 1: type mismatch, expected number but got string')
enddef

def Test_arglistid()
  CheckDefFailure(['arglistid("x")'], 'E1013: Argument 1: type mismatch, expected number but got string')
  CheckDefFailure(['arglistid(1, "y")'], 'E1013: Argument 2: type mismatch, expected number but got string')
  CheckDefFailure(['arglistid("x", "y")'], 'E1013: Argument 1: type mismatch, expected number but got string')
enddef

def Test_argv()
  CheckDefFailure(['argv("x")'], 'E1013: Argument 1: type mismatch, expected number but got string')
  CheckDefFailure(['argv(1, "x")'], 'E1013: Argument 2: type mismatch, expected number but got string')
  CheckDefFailure(['argv("x", "y")'], 'E1013: Argument 1: type mismatch, expected number but got string')
enddef

def Test_assert_equalfile()
  CheckDefFailure(['assert_equalfile(1, "f2")'], 'E1013: Argument 1: type mismatch, expected string but got number')
  CheckDefFailure(['assert_equalfile("f1", true)'], 'E1013: Argument 2: type mismatch, expected string but got bool')
  CheckDefFailure(['assert_equalfile("f1", "f2", ["a"])'], 'E1013: Argument 3: type mismatch, expected string but got list<string>')
enddef

def Test_assert_exception()
  CheckDefFailure(['assert_exception({})'], 'E1013: Argument 1: type mismatch, expected string but got dict<unknown>')
  CheckDefFailure(['assert_exception("E1:", v:null)'], 'E1013: Argument 2: type mismatch, expected string but got special')
enddef

def Test_assert_match()
  CheckDefFailure(['assert_match({}, "b")'], 'E1013: Argument 1: type mismatch, expected string but got dict<unknown>')
  CheckDefFailure(['assert_match("a", 1)'], 'E1013: Argument 2: type mismatch, expected string but got number')
  CheckDefFailure(['assert_match("a", "b", null)'], 'E1013: Argument 3: type mismatch, expected string but got special')
enddef

def Test_assert_notmatch()
  CheckDefFailure(['assert_notmatch({}, "b")'], 'E1013: Argument 1: type mismatch, expected string but got dict<unknown>')
  CheckDefFailure(['assert_notmatch("a", 1)'], 'E1013: Argument 2: type mismatch, expected string but got number')
  CheckDefFailure(['assert_notmatch("a", "b", null)'], 'E1013: Argument 3: type mismatch, expected string but got special')
enddef

def Test_assert_report()
  CheckDefAndScriptFailure2(['assert_report([1, 2])'], 'E1013: Argument 1: type mismatch, expected string but got list<number>', 'E1174: String required for argument 1')
enddef

def Test_balloon_show()
  CheckGui
  CheckFeature balloon_eval

  assert_fails('balloon_show(10)', 'E1174:')
  assert_fails('balloon_show(true)', 'E1174:')

  CheckDefAndScriptFailure2(['balloon_show(1.2)'], 'E1013: Argument 1: type mismatch, expected string but got float', 'E1174: String required for argument 1')
  CheckDefAndScriptFailure2(['balloon_show({"a": 10})'], 'E1013: Argument 1: type mismatch, expected string but got dict<number>', 'E1174: String required for argument 1')
enddef

def Test_balloon_split()
  CheckFeature balloon_eval_term

  assert_fails('balloon_split([])', 'E1174:')
  assert_fails('balloon_split(true)', 'E1174:')
enddef

def Test_browse()
  CheckFeature browse

  var lines =<< trim END
      browse(1, 2, 3, 4)
  END
  CheckDefExecAndScriptFailure(lines, 'E1174: String required for argument 2')
  lines =<< trim END
      browse(1, 'title', 3, 4)
  END
  CheckDefExecAndScriptFailure(lines, 'E1174: String required for argument 3')
  lines =<< trim END
      browse(1, 'title', 'dir', 4)
  END
  CheckDefExecAndScriptFailure(lines, 'E1174: String required for argument 4')
enddef

def Test_browsedir()
  CheckDefFailure(['browsedir({}, "b")'], 'E1013: Argument 1: type mismatch, expected string but got dict<unknown>')
  CheckDefFailure(['browsedir("a", [])'], 'E1013: Argument 2: type mismatch, expected string but got list<unknown>')
enddef

def Test_bufadd()
  assert_fails('bufadd([])', 'E730:')
enddef

def Test_bufexists()
  assert_fails('bufexists(true)', 'E1174:')
enddef

def Test_buflisted()
  var res: bool = buflisted('asdf')
  assert_equal(false, res)
  assert_fails('buflisted(true)', 'E1174:')
  assert_fails('buflisted([])', 'E1174:')
enddef

def Test_bufload()
  assert_fails('bufload([])', 'E730:')
enddef

def Test_bufloaded()
  assert_fails('bufloaded(true)', 'E1174:')
  assert_fails('bufloaded([])', 'E1174:')
enddef

def Test_bufname()
  split SomeFile
  bufname('%')->assert_equal('SomeFile')
  edit OtherFile
  bufname('#')->assert_equal('SomeFile')
  close
  assert_fails('bufname(true)', 'E1138:')
  assert_fails('bufname([])', 'E745:')
enddef

def Test_bufnr()
  var buf = bufnr()
  bufnr('%')->assert_equal(buf)

  buf = bufnr('Xdummy', true)
  buf->assert_notequal(-1)
  exe 'bwipe! ' .. buf
enddef

def Test_bufwinid()
  var origwin = win_getid()
  below split SomeFile
  var SomeFileID = win_getid()
  below split OtherFile
  below split SomeFile
  bufwinid('SomeFile')->assert_equal(SomeFileID)

  win_gotoid(origwin)
  only
  bwipe SomeFile
  bwipe OtherFile

  assert_fails('bufwinid(true)', 'E1138:')
  assert_fails('bufwinid([])', 'E745:')
enddef

def Test_bufwinnr()
  assert_fails('bufwinnr(true)', 'E1138:')
  assert_fails('bufwinnr([])', 'E745:')
enddef

def Test_byte2line()
  CheckDefFailure(['byte2line("1")'], 'E1013: Argument 1: type mismatch, expected number but got string')
  CheckDefFailure(['byte2line([])'], 'E1013: Argument 1: type mismatch, expected number but got list<unknown>')
  assert_equal(-1, byte2line(0))
enddef

def Test_call_call()
  var l = [3, 2, 1]
  call('reverse', [l])
  l->assert_equal([1, 2, 3])
enddef

def Test_ch_canread()
  if !has('channel')
    CheckFeature channel
  endif
  CheckDefFailure(['ch_canread(10)'], 'E1013: Argument 1: type mismatch, expected channel but got number')
enddef

def Test_ch_close()
  if !has('channel')
    CheckFeature channel
  endif
  CheckDefFailure(['ch_close("c")'], 'E1013: Argument 1: type mismatch, expected channel but got string')
enddef

def Test_ch_close_in()
  if !has('channel')
    CheckFeature channel
  endif
  CheckDefFailure(['ch_close_in(true)'], 'E1013: Argument 1: type mismatch, expected channel but got bool')
enddef

def Test_ch_info()
  if !has('channel')
    CheckFeature channel
  endif
  CheckDefFailure(['ch_info([1])'], 'E1013: Argument 1: type mismatch, expected channel but got list<number>')
enddef

def Test_ch_logfile()
  if !has('channel')
    CheckFeature channel
  endif
  assert_fails('ch_logfile(true)', 'E1174:')
  assert_fails('ch_logfile("foo", true)', 'E1174:')

  CheckDefAndScriptFailure2(['ch_logfile(1)'], 'E1013: Argument 1: type mismatch, expected string but got number', 'E1174: String required for argument 1')
  CheckDefAndScriptFailure2(['ch_logfile("a", true)'], 'E1013: Argument 2: type mismatch, expected string but got bool', 'E1174: String required for argument 2')
enddef

def Test_ch_open()
  if !has('channel')
    CheckFeature channel
  endif
  CheckDefAndScriptFailure2(['ch_open({"a": 10}, "a")'], 'E1013: Argument 1: type mismatch, expected string but got dict<number>', 'E1174: String required for argument 1')
  CheckDefAndScriptFailure2(['ch_open("a", [1])'], 'E1013: Argument 2: type mismatch, expected dict<any> but got list<number>', 'E1206: Dictionary required for argument 2')
enddef

def Test_char2nr()
  char2nr('あ', true)->assert_equal(12354)

  assert_fails('char2nr(true)', 'E1174:')
enddef

def Test_charclass()
  assert_fails('charclass(true)', 'E1174:')
enddef

def Test_charcol()
  CheckDefFailure(['charcol(10)'], 'E1013: Argument 1: type mismatch, expected string but got number')
  CheckDefFailure(['charcol({a: 10})'], 'E1013: Argument 1: type mismatch, expected string but got dict<number>')
  new
  setline(1, ['abcdefgh'])
  cursor(1, 4)
  assert_equal(4, charcol('.'))
  assert_equal(9, charcol([1, '$']))
  assert_equal(0, charcol([10, '$']))
  bw!
enddef

def Test_charidx()
  CheckDefFailure(['charidx("a", "b")'], 'E1013: Argument 2: type mismatch, expected number but got string')
  CheckDefFailure(['charidx(0z10, 1)'], 'E1013: Argument 1: type mismatch, expected string but got blob')
  CheckDefFailure(['charidx("a", 1, "")'], 'E1013: Argument 3: type mismatch, expected bool but got string')
enddef

def Test_chdir()
  assert_fails('chdir(true)', 'E1174:')
enddef

def Test_cindent()
  CheckDefFailure(['cindent([])'], 'E1013: Argument 1: type mismatch, expected string but got list<unknown>')
  CheckDefFailure(['cindent(null)'], 'E1013: Argument 1: type mismatch, expected string but got special')
  assert_equal(-1, cindent(0))
  assert_equal(0, cindent('.'))
enddef

def Test_clearmatches()
  CheckDefFailure(['clearmatches("x")'], 'E1013: Argument 1: type mismatch, expected number but got string')
enddef

def Test_col()
  new
  setline(1, 'abcdefgh')
  cursor(1, 4)
  assert_equal(4, col('.'))
  col([1, '$'])->assert_equal(9)
  assert_equal(0, col([10, '$']))

  assert_fails('col(true)', 'E1174:')

  CheckDefFailure(['col(10)'], 'E1013: Argument 1: type mismatch, expected string but got number')
  CheckDefFailure(['col({a: 10})'], 'E1013: Argument 1: type mismatch, expected string but got dict<number>')
  CheckDefFailure(['col(true)'], 'E1013: Argument 1: type mismatch, expected string but got bool')
  bw!
enddef

def Test_confirm()
  if !has('dialog_con') && !has('dialog_gui')
    CheckFeature dialog_con
  endif

  assert_fails('confirm(true)', 'E1174:')
  assert_fails('confirm("yes", true)', 'E1174:')
  assert_fails('confirm("yes", "maybe", 2, true)', 'E1174:')
enddef

def Test_complete_info()
  CheckDefFailure(['complete_info("")'], 'E1013: Argument 1: type mismatch, expected list<string> but got string')
  CheckDefFailure(['complete_info({})'], 'E1013: Argument 1: type mismatch, expected list<string> but got dict<unknown>')
  assert_equal({'pum_visible': 0, 'mode': '', 'selected': -1, 'items': []}, complete_info())
  assert_equal({'mode': '', 'items': []}, complete_info(['mode', 'items']))
enddef

def Test_copy_return_type()
  var l = copy([1, 2, 3])
  var res = 0
  for n in l
    res += n
  endfor
  res->assert_equal(6)

  var dl = deepcopy([1, 2, 3])
  res = 0
  for n in dl
    res += n
  endfor
  res->assert_equal(6)

  dl = deepcopy([1, 2, 3], true)
enddef

def Test_count()
  count('ABC ABC ABC', 'b', true)->assert_equal(3)
  count('ABC ABC ABC', 'b', false)->assert_equal(0)
enddef

def Test_cursor()
  new
  setline(1, range(4))
  cursor(2, 1)
  assert_equal(2, getcurpos()[1])
  cursor('$', 1)
  assert_equal(4, getcurpos()[1])

  var lines =<< trim END
    cursor('2', 1)
  END
  CheckDefExecAndScriptFailure(lines, 'E1209:')
enddef

def Test_debugbreak()
  CheckMSWindows
  CheckDefFailure(['debugbreak("x")'], 'E1013: Argument 1: type mismatch, expected number but got string')
enddef

def Test_delete()
  var res: bool = delete('doesnotexist')
  assert_equal(true, res)

  CheckDefFailure(['delete(10)'], 'E1013: Argument 1: type mismatch, expected string but got number')
  CheckDefFailure(['delete("a", 10)'], 'E1013: Argument 2: type mismatch, expected string but got number')
enddef

def Test_diff_filler()
  CheckDefFailure(['diff_filler([])'], 'E1013: Argument 1: type mismatch, expected string but got list<unknown>')
  CheckDefFailure(['diff_filler(true)'], 'E1013: Argument 1: type mismatch, expected string but got bool')
  assert_equal(0, diff_filler(1))
  assert_equal(0, diff_filler('.'))
enddef

def Test_escape()
  CheckDefFailure(['escape("a", 10)'], 'E1013: Argument 2: type mismatch, expected string but got number')
  CheckDefFailure(['escape(10, " ")'], 'E1013: Argument 1: type mismatch, expected string but got number')
  CheckDefFailure(['escape(true, false)'], 'E1013: Argument 1: type mismatch, expected string but got bool')
  assert_equal('a\:b', escape("a:b", ":"))
enddef

def Test_eval()
  CheckDefFailure(['eval(10)'], 'E1013: Argument 1: type mismatch, expected string but got number')
  CheckDefFailure(['eval(null)'], 'E1013: Argument 1: type mismatch, expected string but got special')
  assert_equal(2, eval('1 + 1'))
enddef

def Test_executable()
  assert_false(executable(""))
  assert_false(executable(test_null_string()))

  CheckDefExecFailure(['echo executable(123)'], 'E1013:')
  CheckDefExecFailure(['echo executable(true)'], 'E1013:')
enddef

def Test_execute()
  var res = execute("echo 'hello'")
  assert_equal("\nhello", res)
  res = execute(["echo 'here'", "echo 'there'"])
  assert_equal("\nhere\nthere", res)

  CheckDefFailure(['execute(123)'], 'E1013: Argument 1: type mismatch, expected string but got number')
  CheckDefFailure(['execute([123])'], 'E1013: Argument 1: type mismatch, expected list<string> but got list<number>')
  CheckDefExecFailure(['echo execute(["xx", 123])'], 'E492')
  CheckDefFailure(['execute("xx", 123)'], 'E1013: Argument 2: type mismatch, expected string but got number')
enddef

def Test_exepath()
  CheckDefExecFailure(['echo exepath(true)'], 'E1013:')
  CheckDefExecFailure(['echo exepath(v:null)'], 'E1013:')
  CheckDefExecFailure(['echo exepath("")'], 'E1175:')
enddef

def Test_exists()
  CheckDefFailure(['exists(10)'], 'E1013: Argument 1: type mismatch, expected string but got number')
  call assert_equal(1, exists('&tabstop'))
enddef

def Test_expand()
  split SomeFile
  expand('%', true, true)->assert_equal(['SomeFile'])
  close
enddef

def Test_expandcmd()
  $FOO = "blue"
  assert_equal("blue sky", expandcmd("`=$FOO .. ' sky'`"))

  assert_equal("yes", expandcmd("`={a: 'yes'}['a']`"))
enddef

def Test_extend_arg_types()
  g:number_one = 1
  g:string_keep = 'keep'
  var lines =<< trim END
      assert_equal([1, 2, 3], extend([1, 2], [3]))
      assert_equal([3, 1, 2], extend([1, 2], [3], 0))
      assert_equal([1, 3, 2], extend([1, 2], [3], 1))
      assert_equal([1, 3, 2], extend([1, 2], [3], g:number_one))

      assert_equal({a: 1, b: 2, c: 3}, extend({a: 1, b: 2}, {c: 3}))
      assert_equal({a: 1, b: 4}, extend({a: 1, b: 2}, {b: 4}))
      assert_equal({a: 1, b: 2}, extend({a: 1, b: 2}, {b: 4}, 'keep'))
      assert_equal({a: 1, b: 2}, extend({a: 1, b: 2}, {b: 4}, g:string_keep))

      var res: list<dict<any>>
      extend(res, mapnew([1, 2], (_, v) => ({})))
      assert_equal([{}, {}], res)
  END
  CheckDefAndScriptSuccess(lines)

  CheckDefFailure(['extend("a", 1)'], 'E1013: Argument 1: type mismatch, expected list<any> but got string')
  CheckDefFailure(['extend([1, 2], 3)'], 'E1013: Argument 2: type mismatch, expected list<number> but got number')
  CheckDefFailure(['extend([1, 2], ["x"])'], 'E1013: Argument 2: type mismatch, expected list<number> but got list<string>')
  CheckDefFailure(['extend([1, 2], [3], "x")'], 'E1013: Argument 3: type mismatch, expected number but got string')

  CheckDefFailure(['extend({a: 1}, 42)'], 'E1013: Argument 2: type mismatch, expected dict<number> but got number')
  CheckDefFailure(['extend({a: 1}, {b: "x"})'], 'E1013: Argument 2: type mismatch, expected dict<number> but got dict<string>')
  CheckDefFailure(['extend({a: 1}, {b: 2}, 1)'], 'E1013: Argument 3: type mismatch, expected string but got number')

  CheckDefFailure(['extend([1], ["b"])'], 'E1013: Argument 2: type mismatch, expected list<number> but got list<string>')
  CheckDefExecFailure(['extend([1], ["b", 1])'], 'E1013: Argument 2: type mismatch, expected list<number> but got list<any>')
enddef

def Test_extendnew()
  assert_equal([1, 2, 'a'], extendnew([1, 2], ['a']))
  assert_equal({one: 1, two: 'a'}, extendnew({one: 1}, {two: 'a'}))

  CheckDefFailure(['extendnew({a: 1}, 42)'], 'E1013: Argument 2: type mismatch, expected dict<number> but got number')
  CheckDefFailure(['extendnew({a: 1}, [42])'], 'E1013: Argument 2: type mismatch, expected dict<number> but got list<number>')
  CheckDefFailure(['extendnew([1, 2], "x")'], 'E1013: Argument 2: type mismatch, expected list<number> but got string')
  CheckDefFailure(['extendnew([1, 2], {x: 1})'], 'E1013: Argument 2: type mismatch, expected list<number> but got dict<number>')
enddef

def Test_extend_return_type()
  var l = extend([1, 2], [3])
  var res = 0
  for n in l
    res += n
  endfor
  res->assert_equal(6)
enddef

func g:ExtendDict(d)
  call extend(a:d, #{xx: 'x'})
endfunc

def Test_extend_dict_item_type()
  var lines =<< trim END
       var d: dict<number> = {a: 1}
       extend(d, {b: 2})
  END
  CheckDefAndScriptSuccess(lines)

  lines =<< trim END
       var d: dict<number> = {a: 1}
       extend(d, {b: 'x'})
  END
  CheckDefAndScriptFailure(lines, 'E1013: Argument 2: type mismatch, expected dict<number> but got dict<string>', 2)

  lines =<< trim END
       var d: dict<number> = {a: 1}
       g:ExtendDict(d)
  END
  CheckDefExecFailure(lines, 'E1012: Type mismatch; expected number but got string', 0)
  CheckScriptFailure(['vim9script'] + lines, 'E1012:', 1)
enddef

func g:ExtendList(l)
  call extend(a:l, ['x'])
endfunc

def Test_extend_list_item_type()
  var lines =<< trim END
       var l: list<number> = [1]
       extend(l, [2])
  END
  CheckDefAndScriptSuccess(lines)

  lines =<< trim END
       var l: list<number> = [1]
       extend(l, ['x'])
  END
  CheckDefAndScriptFailure(lines, 'E1013: Argument 2: type mismatch, expected list<number> but got list<string>', 2)

  lines =<< trim END
       var l: list<number> = [1]
       g:ExtendList(l)
  END
  CheckDefExecFailure(lines, 'E1012: Type mismatch; expected number but got string', 0)
  CheckScriptFailure(['vim9script'] + lines, 'E1012:', 1)
enddef

def Test_extend_with_error_function()
  var lines =<< trim END
      vim9script
      def F()
        {
          var m = 10
        }
        echo m
      enddef

      def Test()
        var d: dict<any> = {}
        d->extend({A: 10, Func: function('F', [])})
      enddef

      Test()
  END
  CheckScriptFailure(lines, 'E1001: Variable not found: m')
enddef

def Test_feedkeys()
  CheckDefFailure(['feedkeys(10)'], 'E1013: Argument 1: type mismatch, expected string but got number')
  CheckDefFailure(['feedkeys("x", 10)'], 'E1013: Argument 2: type mismatch, expected string but got number')
  CheckDefFailure(['feedkeys([], {})'], 'E1013: Argument 1: type mismatch, expected string but got list<unknown>')
  g:TestVar = 1
  feedkeys(":g:TestVar = 789\n", 'xt')
  assert_equal(789, g:TestVar)
  unlet g:TestVar
enddef

def Test_indent()
  CheckDefAndScriptFailure2(['indent([1])'], 'E1013: Argument 1: type mismatch, expected string but got list<number>', 'E745: Using a List as a Number')
  CheckDefAndScriptFailure2(['indent(true)'], 'E1013: Argument 1: type mismatch, expected string but got bool', 'E1138: Using a Bool as a Number')
  assert_equal(0, indent(1))
enddef

def Test_input()
  CheckDefFailure(['input(5)'], 'E1013: Argument 1: type mismatch, expected string but got number')
  CheckDefAndScriptFailure2(['input(["a"])'], 'E1013: Argument 1: type mismatch, expected string but got list<string>', 'E730: Using a List as a String')
  CheckDefFailure(['input("p", 10)'], 'E1013: Argument 2: type mismatch, expected string but got number')
  CheckDefAndScriptFailure2(['input("p", "q", 20)'], 'E1013: Argument 3: type mismatch, expected string but got number', 'E180: Invalid complete value')
enddef

def Test_inputdialog()
  CheckDefFailure(['inputdialog(5)'], 'E1013: Argument 1: type mismatch, expected string but got number')
  CheckDefAndScriptFailure2(['inputdialog(["a"])'], 'E1013: Argument 1: type mismatch, expected string but got list<string>', 'E730: Using a List as a String')
  CheckDefFailure(['inputdialog("p", 10)'], 'E1013: Argument 2: type mismatch, expected string but got number')
  CheckDefFailure(['inputdialog("p", "q", 20)'], 'E1013: Argument 3: type mismatch, expected string but got number')
enddef

def Test_job_info_return_type()
  if has('job')
    job_start(&shell)
    var jobs = job_info()
    assert_equal('list<job>', typename(jobs))
    assert_equal('dict<any>', typename(job_info(jobs[0])))
    job_stop(jobs[0])
  endif
enddef

def Test_filereadable()
  assert_false(filereadable(""))
  assert_false(filereadable(test_null_string()))

  CheckDefExecFailure(['echo filereadable(123)'], 'E1013:')
  CheckDefExecFailure(['echo filereadable(true)'], 'E1013:')
enddef

def Test_filewritable()
  assert_false(filewritable(""))
  assert_false(filewritable(test_null_string()))

  CheckDefExecFailure(['echo filewritable(123)'], 'E1013:')
  CheckDefExecFailure(['echo filewritable(true)'], 'E1013:')
enddef

def Test_finddir()
  CheckDefAndScriptFailure2(['finddir(true)'], 'E1013: Argument 1: type mismatch, expected string but got bool', 'E1174: String required for argument 1')
  CheckDefAndScriptFailure2(['finddir(v:null)'], 'E1013: Argument 1: type mismatch, expected string but got special', 'E1174: String required for argument 1')
  CheckDefExecFailure(['echo finddir("")'], 'E1175:')
  CheckDefAndScriptFailure2(['finddir("a", [])'], 'E1013: Argument 2: type mismatch, expected string but got list<unknown>', 'E730: Using a List as a String')
  CheckDefAndScriptFailure2(['finddir("a", "b", "c")'], 'E1013: Argument 3: type mismatch, expected number but got string', 'E1030: Using a String as a Number')
enddef

def Test_findfile()
  CheckDefExecFailure(['findfile(true)'], 'E1013: Argument 1: type mismatch, expected string but got bool')
  CheckDefExecFailure(['findfile(v:null)'], 'E1013: Argument 1: type mismatch, expected string but got special')
  CheckDefExecFailure(['findfile("")'], 'E1175:')
  CheckDefAndScriptFailure2(['findfile("a", [])'], 'E1013: Argument 2: type mismatch, expected string but got list<unknown>', 'E730: Using a List as a String')
  CheckDefAndScriptFailure2(['findfile("a", "b", "c")'], 'E1013: Argument 3: type mismatch, expected number but got string', 'E1030: Using a String as a Number')
enddef

def Test_flattennew()
  var lines =<< trim END
      var l = [1, [2, [3, 4]], 5]
      call assert_equal([1, 2, 3, 4, 5], flattennew(l))
      call assert_equal([1, [2, [3, 4]], 5], l)

      call assert_equal([1, 2, [3, 4], 5], flattennew(l, 1))
      call assert_equal([1, [2, [3, 4]], 5], l)
  END
  CheckDefAndScriptSuccess(lines)

  lines =<< trim END
      echo flatten([1, 2, 3])
  END
  CheckDefAndScriptFailure(lines, 'E1158:')
enddef

" Test for float functions argument type
def Test_float_funcs_args()
  CheckFeature float

  # acos()
  CheckDefFailure(['acos("a")'], 'E1013: Argument 1: type mismatch, expected number but got string')
  # asin()
  CheckDefFailure(['asin("a")'], 'E1013: Argument 1: type mismatch, expected number but got string')
  # atan()
  CheckDefFailure(['atan("a")'], 'E1013: Argument 1: type mismatch, expected number but got string')
  # atan2()
  CheckDefFailure(['atan2("a", 1.1)'], 'E1013: Argument 1: type mismatch, expected number but got string')
  CheckDefFailure(['atan2(1.2, "a")'], 'E1013: Argument 2: type mismatch, expected number but got string')
  CheckDefFailure(['atan2(1.2)'], 'E119:')
  # ceil()
  CheckDefFailure(['ceil("a")'], 'E1013: Argument 1: type mismatch, expected number but got string')
  # cos()
  CheckDefFailure(['cos("a")'], 'E1013: Argument 1: type mismatch, expected number but got string')
  # cosh()
  CheckDefFailure(['cosh("a")'], 'E1013: Argument 1: type mismatch, expected number but got string')
  # exp()
  CheckDefFailure(['exp("a")'], 'E1013: Argument 1: type mismatch, expected number but got string')
  # float2nr()
  CheckDefFailure(['float2nr("a")'], 'E1013: Argument 1: type mismatch, expected number but got string')
  # floor()
  CheckDefFailure(['floor("a")'], 'E1013: Argument 1: type mismatch, expected number but got string')
  # fmod()
  CheckDefFailure(['fmod(1.1, "a")'], 'E1013: Argument 2: type mismatch, expected number but got string')
  CheckDefFailure(['fmod("a", 1.1)'], 'E1013: Argument 1: type mismatch, expected number but got string')
  CheckDefFailure(['fmod(1.1)'], 'E119:')
  # isinf()
  CheckDefFailure(['isinf("a")'], 'E1013: Argument 1: type mismatch, expected number but got string')
  # isnan()
  CheckDefFailure(['isnan("a")'], 'E1013: Argument 1: type mismatch, expected number but got string')
  # log()
  CheckDefFailure(['log("a")'], 'E1013: Argument 1: type mismatch, expected number but got string')
  # log10()
  CheckDefFailure(['log10("a")'], 'E1013: Argument 1: type mismatch, expected number but got string')
  # pow()
  CheckDefFailure(['pow("a", 1.1)'], 'E1013: Argument 1: type mismatch, expected number but got string')
  CheckDefFailure(['pow(1.1, "a")'], 'E1013: Argument 2: type mismatch, expected number but got string')
  CheckDefFailure(['pow(1.1)'], 'E119:')
  # round()
  CheckDefFailure(['round("a")'], 'E1013: Argument 1: type mismatch, expected number but got string')
  # sin()
  CheckDefFailure(['sin("a")'], 'E1013: Argument 1: type mismatch, expected number but got string')
  # sinh()
  CheckDefFailure(['sinh("a")'], 'E1013: Argument 1: type mismatch, expected number but got string')
  # sqrt()
  CheckDefFailure(['sqrt("a")'], 'E1013: Argument 1: type mismatch, expected number but got string')
  # tan()
  CheckDefFailure(['tan("a")'], 'E1013: Argument 1: type mismatch, expected number but got string')
  # tanh()
  CheckDefFailure(['tanh("a")'], 'E1013: Argument 1: type mismatch, expected number but got string')
  # trunc()
  CheckDefFailure(['trunc("a")'], 'E1013: Argument 1: type mismatch, expected number but got string')
enddef

def Test_fnameescape()
  CheckDefFailure(['fnameescape(10)'], 'E1013: Argument 1: type mismatch, expected string but got number')
  assert_equal('\+a\%b\|', fnameescape('+a%b|'))
enddef

def Test_fnamemodify()
  CheckDefSuccess(['echo fnamemodify(test_null_string(), ":p")'])
  CheckDefSuccess(['echo fnamemodify("", ":p")'])
  CheckDefSuccess(['echo fnamemodify("file", test_null_string())'])
  CheckDefSuccess(['echo fnamemodify("file", "")'])

  CheckDefExecFailure(['echo fnamemodify(true, ":p")'], 'E1013: Argument 1: type mismatch, expected string but got bool')
  CheckDefExecFailure(['echo fnamemodify(v:null, ":p")'], 'E1013: Argument 1: type mismatch, expected string but got special')
  CheckDefExecFailure(['echo fnamemodify("file", true)'],  'E1013: Argument 2: type mismatch, expected string but got bool')
enddef

def Wrong_dict_key_type(items: list<number>): list<number>
  return filter(items, (_, val) => get({[val]: 1}, 'x'))
enddef

def Test_filter_wrong_dict_key_type()
  assert_fails('Wrong_dict_key_type([1, v:null, 3])', 'E1013:')
enddef

def Test_filter_return_type()
  var l = filter([1, 2, 3], (_, _) => 1)
  var res = 0
  for n in l
    res += n
  endfor
  res->assert_equal(6)
enddef

def Test_filter_missing_argument()
  var dict = {aa: [1], ab: [2], ac: [3], de: [4]}
  var res = dict->filter((k, _) => k =~ 'a' && k !~ 'b')
  res->assert_equal({aa: [1], ac: [3]})
enddef

def Test_foldclosed()
  CheckDefFailure(['foldclosed(function("min"))'], 'E1013: Argument 1: type mismatch, expected string but got func(...): any')
  assert_equal(-1, foldclosed(1))
  assert_equal(-1, foldclosed('$'))
enddef

def Test_foldclosedend()
  CheckDefFailure(['foldclosedend(true)'], 'E1013: Argument 1: type mismatch, expected string but got bool')
  assert_equal(-1, foldclosedend(1))
  assert_equal(-1, foldclosedend('w0'))
enddef

def Test_foldlevel()
  CheckDefFailure(['foldlevel(0z10)'], 'E1013: Argument 1: type mismatch, expected string but got blob')
  assert_equal(0, foldlevel(1))
  assert_equal(0, foldlevel('.'))
enddef

def Test_foldtextresult()
  CheckDefFailure(['foldtextresult(1.1)'], 'E1013: Argument 1: type mismatch, expected string but got float')
  assert_equal('', foldtextresult(1))
  assert_equal('', foldtextresult('.'))
enddef

def Test_fullcommand()
  assert_equal('next', fullcommand('n'))
  assert_equal('noremap', fullcommand('no'))
  assert_equal('noremap', fullcommand('nor'))
  assert_equal('normal', fullcommand('norm'))

  assert_equal('', fullcommand('k'))
  assert_equal('keepmarks', fullcommand('ke'))
  assert_equal('keepmarks', fullcommand('kee'))
  assert_equal('keepmarks', fullcommand('keep'))
  assert_equal('keepjumps', fullcommand('keepj'))

  assert_equal('dlist', fullcommand('dl'))
  assert_equal('', fullcommand('dp'))
  assert_equal('delete', fullcommand('del'))
  assert_equal('', fullcommand('dell'))
  assert_equal('', fullcommand('delp'))

  assert_equal('srewind', fullcommand('sre'))
  assert_equal('scriptnames', fullcommand('scr'))
  assert_equal('', fullcommand('scg'))
enddef

def Test_garbagecollect()
  garbagecollect(true)
enddef

def Test_getbufinfo()
  var bufinfo = getbufinfo(bufnr())
  getbufinfo('%')->assert_equal(bufinfo)

  edit Xtestfile1
  hide edit Xtestfile2
  hide enew
  getbufinfo({bufloaded: true, buflisted: true, bufmodified: false})
      ->len()->assert_equal(3)
  bwipe Xtestfile1 Xtestfile2
enddef

def Test_getbufline()
  e SomeFile
  var buf = bufnr()
  e #
  var lines = ['aaa', 'bbb', 'ccc']
  setbufline(buf, 1, lines)
  getbufline('#', 1, '$')->assert_equal(lines)
  getbufline(-1, '$', '$')->assert_equal([])
  getbufline(-1, 1, '$')->assert_equal([])

  bwipe!
enddef

def Test_getchangelist()
  new
  setline(1, 'some text')
  var changelist = bufnr()->getchangelist()
  getchangelist('%')->assert_equal(changelist)
  bwipe!
enddef

def Test_getchar()
  while getchar(0)
  endwhile
  getchar(true)->assert_equal(0)
enddef

def Test_getenv()
  if getenv('does-not_exist') == ''
    assert_report('getenv() should return null')
  endif
  if getenv('does-not_exist') == null
  else
    assert_report('getenv() should return null')
  endif
  $SOMEENVVAR = 'some'
  assert_equal('some', getenv('SOMEENVVAR'))
  unlet $SOMEENVVAR
enddef

def Test_getcompletion()
  set wildignore=*.vim,*~
  var l = getcompletion('run', 'file', true)
  l->assert_equal([])
  set wildignore&
enddef

def Test_getcurpos()
  CheckDefFailure(['getcursorcharpos("x")'], 'E1013: Argument 1: type mismatch, expected number but got string')
enddef

def Test_getcursorcharpos()
  CheckDefFailure(['getcursorcharpos("x")'], 'E1013: Argument 1: type mismatch, expected number but got string')
enddef

def Test_getcwd()
  CheckDefFailure(['getcwd("x")'], 'E1013: Argument 1: type mismatch, expected number but got string')
  CheckDefFailure(['getcwd("x", 1)'], 'E1013: Argument 1: type mismatch, expected number but got string')
  CheckDefFailure(['getcwd(1, "x")'], 'E1013: Argument 2: type mismatch, expected number but got string')
enddef

def Test_getloclist_return_type()
  var l = getloclist(1)
  l->assert_equal([])

  var d = getloclist(1, {items: 0})
  d->assert_equal({items: []})
enddef

def Test_getfontname()
  CheckDefFailure(['getfontname(10)'], 'E1013: Argument 1: type mismatch, expected string but got number')
enddef

def Test_getfperm()
  assert_equal('', getfperm(""))
  assert_equal('', getfperm(test_null_string()))

  CheckDefExecFailure(['echo getfperm(true)'], 'E1013:')
  CheckDefExecFailure(['echo getfperm(v:null)'], 'E1013:')
enddef

def Test_getfsize()
  assert_equal(-1, getfsize(""))
  assert_equal(-1, getfsize(test_null_string()))

  CheckDefExecFailure(['echo getfsize(true)'], 'E1013:')
  CheckDefExecFailure(['echo getfsize(v:null)'], 'E1013:')
enddef

def Test_getftime()
  assert_equal(-1, getftime(""))
  assert_equal(-1, getftime(test_null_string()))

  CheckDefExecFailure(['echo getftime(true)'], 'E1013:')
  CheckDefExecFailure(['echo getftime(v:null)'], 'E1013:')
enddef

def Test_getftype()
  assert_equal('', getftype(""))
  assert_equal('', getftype(test_null_string()))

  CheckDefExecFailure(['echo getftype(true)'], 'E1013:')
  CheckDefExecFailure(['echo getftype(v:null)'], 'E1013:')
enddef

def Test_getjumplist()
  CheckDefFailure(['getjumplist("x")'], 'E1013: Argument 1: type mismatch, expected number but got string')
  CheckDefFailure(['getjumplist("x", 1)'], 'E1013: Argument 1: type mismatch, expected number but got string')
  CheckDefFailure(['getjumplist(1, "x")'], 'E1013: Argument 2: type mismatch, expected number but got string')
enddef

def Test_getline()
  var lines =<< trim END
      new
      setline(1, ['hello', 'there', 'again'])
      assert_equal('hello', getline(1))
      assert_equal('hello', getline('.'))

      normal 2Gvjv
      assert_equal('there', getline("'<"))
      assert_equal('again', getline("'>"))
  END
  CheckDefAndScriptSuccess(lines)

  lines =<< trim END
      echo getline('1')
  END
  CheckDefExecAndScriptFailure(lines, 'E1209:')
enddef

def Test_getmarklist()
  CheckDefFailure(['getmarklist([])'], 'E1013: Argument 1: type mismatch, expected string but got list<unknown>')
  assert_equal([], getmarklist(10000))
  assert_fails('getmarklist("a%b@#")', 'E94:')
enddef

def Test_getmatches()
  CheckDefFailure(['getmatches("x")'], 'E1013: Argument 1: type mismatch, expected number but got string')
enddef

def Test_getpos()
  CheckDefFailure(['getpos(10)'], 'E1013: Argument 1: type mismatch, expected string but got number')
  assert_equal([0, 1, 1, 0], getpos('.'))
  CheckDefExecFailure(['getpos("a")'], 'E1209:')
enddef

def Test_getqflist()
  CheckDefFailure(['getqflist([])'], 'E1013: Argument 1: type mismatch, expected dict<any> but got list<unknown>')
  call assert_equal({}, getqflist({}))
enddef

def Test_getqflist_return_type()
  var l = getqflist()
  l->assert_equal([])

  var d = getqflist({items: 0})
  d->assert_equal({items: []})
enddef

def Test_getreg()
  var lines = ['aaa', 'bbb', 'ccc']
  setreg('a', lines)
  getreg('a', true, true)->assert_equal(lines)
  assert_fails('getreg("ab")', 'E1162:')
enddef

def Test_getreg_return_type()
  var s1: string = getreg('"')
  var s2: string = getreg('"', 1)
  var s3: list<string> = getreg('"', 1, 1)
enddef

def Test_getreginfo()
  var text = 'abc'
  setreg('a', text)
  getreginfo('a')->assert_equal({regcontents: [text], regtype: 'v', isunnamed: false})
  assert_fails('getreginfo("ab")', 'E1162:')
enddef

def Test_getregtype()
  var lines = ['aaa', 'bbb', 'ccc']
  setreg('a', lines)
  getregtype('a')->assert_equal('V')
  assert_fails('getregtype("ab")', 'E1162:')
enddef

def Test_gettabinfo()
  CheckDefFailure(['gettabinfo("x")'], 'E1013: Argument 1: type mismatch, expected number but got string')
enddef

def Test_gettagstack()
  CheckDefFailure(['gettagstack("x")'], 'E1013: Argument 1: type mismatch, expected number but got string')
enddef

def Test_gettext()
  CheckDefFailure(['gettext(10)'], 'E1013: Argument 1: type mismatch, expected string but got number')
  assert_equal('abc', gettext("abc"))
enddef

def Test_getwininfo()
  CheckDefFailure(['getwininfo("x")'], 'E1013: Argument 1: type mismatch, expected number but got string')
enddef

def Test_getwinpos()
  CheckDefFailure(['getwinpos("x")'], 'E1013: Argument 1: type mismatch, expected number but got string')
enddef

def Test_glob()
  glob('runtest.vim', true, true, true)->assert_equal(['runtest.vim'])
enddef

def Test_glob2regpat()
  CheckDefFailure(['glob2regpat(null)'], 'E1013: Argument 1: type mismatch, expected string but got special')
  assert_equal('^$', glob2regpat(''))
enddef

def Test_globpath()
  globpath('.', 'runtest.vim', true, true, true)->assert_equal(['./runtest.vim'])
enddef

def Test_has()
  has('eval', true)->assert_equal(1)
enddef

def Test_has_key()
  var d = {123: 'xx'}
  assert_true(has_key(d, '123'))
  assert_true(has_key(d, 123))
  assert_false(has_key(d, 'x'))
  assert_false(has_key(d, 99))

  CheckDefAndScriptFailure2(['has_key([1, 2], "k")'], 'E1013: Argument 1: type mismatch, expected dict<any> but got list<number>', 'E715: Dictionary required')
  CheckDefAndScriptFailure2(['has_key({"a": 10}, ["a"])'], 'E1013: Argument 2: type mismatch, expected string but got list<string>', 'E730: Using a List as a String')
enddef

def Test_haslocaldir()
  CheckDefFailure(['haslocaldir("x")'], 'E1013: Argument 1: type mismatch, expected number but got string')
  CheckDefFailure(['haslocaldir("x", 1)'], 'E1013: Argument 1: type mismatch, expected number but got string')
  CheckDefFailure(['haslocaldir(1, "x")'], 'E1013: Argument 2: type mismatch, expected number but got string')
enddef

def Test_hasmapto()
  hasmapto('foobar', 'i', true)->assert_equal(0)
  iabbrev foo foobar
  hasmapto('foobar', 'i', true)->assert_equal(1)
  iunabbrev foo
enddef

def Test_histadd()
  CheckDefFailure(['histadd(1, "x")'], 'E1013: Argument 1: type mismatch, expected string but got number')
  CheckDefFailure(['histadd(":", 10)'], 'E1013: Argument 2: type mismatch, expected string but got number')
  histadd("search", 'skyblue')
  assert_equal('skyblue', histget('/', -1))
enddef

def Test_histnr()
  CheckDefFailure(['histnr(10)'], 'E1013: Argument 1: type mismatch, expected string but got number')
  assert_equal(-1, histnr('abc'))
enddef

def Test_hlID()
  CheckDefFailure(['hlID(10)'], 'E1013: Argument 1: type mismatch, expected string but got number')
  assert_equal(0, hlID('NonExistingHighlight'))
enddef

def Test_hlexists()
  CheckDefFailure(['hlexists([])'], 'E1013: Argument 1: type mismatch, expected string but got list<unknown>')
  assert_equal(0, hlexists('NonExistingHighlight'))
enddef

def Test_iconv()
  CheckDefFailure(['iconv(1, "from", "to")'], 'E1013: Argument 1: type mismatch, expected string but got number')
  CheckDefFailure(['iconv("abc", 10, "to")'], 'E1013: Argument 2: type mismatch, expected string but got number')
  CheckDefFailure(['iconv("abc", "from", 20)'], 'E1013: Argument 3: type mismatch, expected string but got number')
  assert_equal('abc', iconv('abc', 'fromenc', 'toenc'))
enddef

def Test_index()
  index(['a', 'b', 'a', 'B'], 'b', 2, true)->assert_equal(3)
enddef

def Test_inputlist()
  CheckDefFailure(['inputlist(10)'], 'E1013: Argument 1: type mismatch, expected list<string> but got number')
  CheckDefFailure(['inputlist("abc")'], 'E1013: Argument 1: type mismatch, expected list<string> but got string')
  CheckDefFailure(['inputlist([1, 2, 3])'], 'E1013: Argument 1: type mismatch, expected list<string> but got list<number>')
  feedkeys("2\<CR>", 't')
  var r: number = inputlist(['a', 'b', 'c'])
  assert_equal(2, r)
enddef

def Test_inputsecret()
  CheckDefFailure(['inputsecret(10)'], 'E1013: Argument 1: type mismatch, expected string but got number')
  CheckDefFailure(['inputsecret("Pass:", 20)'], 'E1013: Argument 2: type mismatch, expected string but got number')
  feedkeys("\<CR>", 't')
  var ans: string = inputsecret('Pass:', '123')
  assert_equal('123', ans)
enddef

let s:number_one = 1
let s:number_two = 2
let s:string_keep = 'keep'

def Test_insert()
  var l = insert([2, 1], 3)
  var res = 0
  for n in l
    res += n
  endfor
  res->assert_equal(6)

  var m: any = []
  insert(m, 4)
  call assert_equal([4], m)
  extend(m, [6], 0)
  call assert_equal([6, 4], m)

  var lines =<< trim END
      insert(test_null_list(), 123)
  END
  CheckDefExecAndScriptFailure(lines, 'E1130:', 1)

  lines =<< trim END
      insert(test_null_blob(), 123)
  END
  CheckDefExecAndScriptFailure(lines, 'E1131:', 1)

  assert_equal([1, 2, 3], insert([2, 3], 1))
  assert_equal([1, 2, 3], insert([2, 3], s:number_one))
  assert_equal([1, 2, 3], insert([1, 2], 3, 2))
  assert_equal([1, 2, 3], insert([1, 2], 3, s:number_two))
  assert_equal(['a', 'b', 'c'], insert(['b', 'c'], 'a'))
  assert_equal(0z1234, insert(0z34, 0x12))

  CheckDefFailure(['insert("a", 1)'], 'E1013: Argument 1: type mismatch, expected list<any> but got string', 1)
  CheckDefFailure(['insert([2, 3], "a")'], 'E1013: Argument 2: type mismatch, expected number but got string', 1)
  CheckDefFailure(['insert([2, 3], 1, "x")'], 'E1013: Argument 3: type mismatch, expected number but got string', 1)
enddef

def Test_invert()
  CheckDefFailure(['invert("x")'], 'E1013: Argument 1: type mismatch, expected number but got string')
enddef

def Test_isdirectory()
  CheckDefFailure(['isdirectory(1.1)'], 'E1013: Argument 1: type mismatch, expected string but got float')
  assert_false(isdirectory('NonExistingDir'))
enddef

def Test_items()
  CheckDefFailure(['[]->items()'], 'E1013: Argument 1: type mismatch, expected dict<any> but got list<unknown>')
  assert_equal([['a', 10], ['b', 20]], {'a': 10, 'b': 20}->items())
  assert_equal([], {}->items())
enddef

def Test_js_decode()
  CheckDefFailure(['js_decode(10)'], 'E1013: Argument 1: type mismatch, expected string but got number')
  assert_equal([1, 2], js_decode('[1,2]'))
enddef

def Test_json_decode()
  CheckDefFailure(['json_decode(true)'], 'E1013: Argument 1: type mismatch, expected string but got bool')
  assert_equal(1.0, json_decode('1.0'))
enddef

def Test_keys()
  CheckDefFailure(['keys([])'], 'E1013: Argument 1: type mismatch, expected dict<any> but got list<unknown>')
  assert_equal(['a'], {a: 'v'}->keys())
  assert_equal([], {}->keys())
enddef

def Test_keys_return_type()
  const var: list<string> = {a: 1, b: 2}->keys()
  var->assert_equal(['a', 'b'])
enddef

def Test_line()
  assert_fails('line(true)', 'E1174:')
enddef

def Test_line2byte()
  CheckDefFailure(['line2byte(true)'], 'E1013: Argument 1: type mismatch, expected string but got bool')
  assert_equal(-1, line2byte(1))
  assert_equal(-1, line2byte(10000))
enddef

def Test_lispindent()
  CheckDefFailure(['lispindent({})'], 'E1013: Argument 1: type mismatch, expected string but got dict<unknown>')
  assert_equal(0, lispindent(1))
enddef

def Test_list2str_str2list_utf8()
  var s = "\u3042\u3044"
  var l = [0x3042, 0x3044]
  str2list(s, true)->assert_equal(l)
  list2str(l, true)->assert_equal(s)
enddef

def SID(): number
  return expand('<SID>')
          ->matchstr('<SNR>\zs\d\+\ze_$')
          ->str2nr()
enddef

def Test_listener_flush()
  CheckDefAndScriptFailure2(['listener_flush([1])'], 'E1013: Argument 1: type mismatch, expected string but got list<number>', 'E730: Using a List as a String')
enddef

def Test_listener_remove()
  CheckDefAndScriptFailure2(['listener_remove("x")'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1030: Using a String as a Number')
enddef

def Test_map_function_arg()
  var lines =<< trim END
      def MapOne(i: number, v: string): string
        return i .. ':' .. v
      enddef
      var l = ['a', 'b', 'c']
      map(l, MapOne)
      assert_equal(['0:a', '1:b', '2:c'], l)
  END
  CheckDefAndScriptSuccess(lines)

  lines =<< trim END
      range(3)->map((a, b, c) => a + b + c)
  END
  CheckDefExecAndScriptFailure(lines, 'E1190: One argument too few')
  lines =<< trim END
      range(3)->map((a, b, c, d) => a + b + c + d)
  END
  CheckDefExecAndScriptFailure(lines, 'E1190: 2 arguments too few')
enddef

def Test_map_item_type()
  var lines =<< trim END
      var l = ['a', 'b', 'c']
      map(l, (k, v) => k .. '/' .. v )
      assert_equal(['0/a', '1/b', '2/c'], l)
  END
  CheckDefAndScriptSuccess(lines)

  lines =<< trim END
    var l: list<number> = [0]
    echo map(l, (_, v) => [])
  END
  CheckDefExecAndScriptFailure(lines, 'E1012: Type mismatch; expected number but got list<unknown>', 2)

  lines =<< trim END
    var l: list<number> = range(2)
    echo map(l, (_, v) => [])
  END
  CheckDefExecAndScriptFailure(lines, 'E1012: Type mismatch; expected number but got list<unknown>', 2)

  lines =<< trim END
    var d: dict<number> = {key: 0}
    echo map(d, (_, v) => [])
  END
  CheckDefExecAndScriptFailure(lines, 'E1012: Type mismatch; expected number but got list<unknown>', 2)
enddef

def Test_maparg()
  var lnum = str2nr(expand('<sflnum>'))
  map foo bar
  maparg('foo', '', false, true)->assert_equal({
        lnum: lnum + 1,
        script: 0,
        mode: ' ',
        silent: 0,
        noremap: 0,
        lhs: 'foo',
        lhsraw: 'foo',
        nowait: 0,
        expr: 0,
        sid: SID(),
        rhs: 'bar',
        buffer: 0})
  unmap foo
enddef

def Test_mapcheck()
  iabbrev foo foobar
  mapcheck('foo', 'i', true)->assert_equal('foobar')
  iunabbrev foo
enddef

def Test_maparg_mapset()
  nnoremap <F3> :echo "hit F3"<CR>
  var mapsave = maparg('<F3>', 'n', false, true)
  mapset('n', false, mapsave)

  nunmap <F3>
enddef

def Test_map_failure()
  CheckFeature job

  var lines =<< trim END
      vim9script
      writefile([], 'Xtmpfile')
      silent e Xtmpfile
      var d = {[bufnr('%')]: {a: 0}}
      au BufReadPost * Func()
      def Func()
          if d->has_key('')
          endif
          eval d[expand('<abuf>')]->mapnew((_, v: dict<job>) => 0)
      enddef
      e
  END
  CheckScriptFailure(lines, 'E1013:')
  au! BufReadPost
  delete('Xtmpfile')
enddef

def Test_matcharg()
  CheckDefFailure(['matcharg("x")'], 'E1013: Argument 1: type mismatch, expected number but got string')
enddef

def Test_matchdelete()
  CheckDefFailure(['matchdelete("x")'], 'E1013: Argument 1: type mismatch, expected number but got string')
  CheckDefFailure(['matchdelete("x", 1)'], 'E1013: Argument 1: type mismatch, expected number but got string')
  CheckDefFailure(['matchdelete(1, "x")'], 'E1013: Argument 2: type mismatch, expected number but got string')
enddef

def Test_max()
  g:flag = true
  var l1: list<number> = g:flag
          ? [1, max([2, 3])]
          : [4, 5]
  assert_equal([1, 3], l1)

  g:flag = false
  var l2: list<number> = g:flag
          ? [1, max([2, 3])]
          : [4, 5]
  assert_equal([4, 5], l2)
enddef

def Test_menu_info()
  CheckDefFailure(['menu_info(10)'], 'E1013: Argument 1: type mismatch, expected string but got number')
  CheckDefFailure(['menu_info(10, "n")'], 'E1013: Argument 1: type mismatch, expected string but got number')
  CheckDefFailure(['menu_info("File", 10)'], 'E1013: Argument 2: type mismatch, expected string but got number')
  assert_equal({}, menu_info('aMenu'))
enddef

def Test_min()
  g:flag = true
  var l1: list<number> = g:flag
          ? [1, min([2, 3])]
          : [4, 5]
  assert_equal([1, 2], l1)

  g:flag = false
  var l2: list<number> = g:flag
          ? [1, min([2, 3])]
          : [4, 5]
  assert_equal([4, 5], l2)
enddef

def Test_mkdir()
  CheckDefAndScriptFailure2(['mkdir(["a"])'], 'E1013: Argument 1: type mismatch, expected string but got list<string>', 'E730: Using a List as a String')
  CheckDefAndScriptFailure2(['mkdir("a", {})'], 'E1013: Argument 2: type mismatch, expected string but got dict<unknown>', 'E731: Using a Dictionary as a String')
  CheckDefAndScriptFailure2(['mkdir("a", "b", "c")'], 'E1013: Argument 3: type mismatch, expected number but got string', 'E1030: Using a String as a Number')
  delete('a', 'rf')
enddef

def Test_nextnonblank()
  CheckDefFailure(['nextnonblank(null)'], 'E1013: Argument 1: type mismatch, expected string but got special')
  assert_equal(0, nextnonblank(1))
enddef

def Test_nr2char()
  nr2char(97, true)->assert_equal('a')
enddef

def Test_or()
  CheckDefFailure(['or("x", 0x2)'], 'E1013: Argument 1: type mismatch, expected number but got string')
  CheckDefFailure(['or(0x1, "x")'], 'E1013: Argument 2: type mismatch, expected number but got string')
enddef

def Test_popup_atcursor()
  CheckDefAndScriptFailure2(['popup_atcursor({"a": 10}, {})'], 'E1013: Argument 1: type mismatch, expected string but got dict<number>', 'E450: buffer number, text or a list required')
  CheckDefAndScriptFailure2(['popup_atcursor("a", [1, 2])'], 'E1013: Argument 2: type mismatch, expected dict<any> but got list<number>', 'E715: Dictionary required')

  # Pass variable of type 'any' to popup_atcursor()
  var what: any = 'Hello'
  var popupID = what->popup_atcursor({moved: 'any'})
  assert_equal(0, popupID->popup_getoptions().tabpage)
  popupID->popup_close()
enddef

def Test_popup_beval()
  CheckDefAndScriptFailure2(['popup_beval({"a": 10}, {})'], 'E1013: Argument 1: type mismatch, expected string but got dict<number>', 'E450: buffer number, text or a list required')
  CheckDefAndScriptFailure2(['popup_beval("a", [1, 2])'], 'E1013: Argument 2: type mismatch, expected dict<any> but got list<number>', 'E715: Dictionary required')
enddef

def Test_popup_create()
  # Pass variable of type 'any' to popup_create()
  var what: any = 'Hello'
  var popupID = what->popup_create({})
  assert_equal(0, popupID->popup_getoptions().tabpage)
  popupID->popup_close()
enddef

def Test_popup_dialog()
  CheckDefAndScriptFailure2(['popup_dialog({"a": 10}, {})'], 'E1013: Argument 1: type mismatch, expected string but got dict<number>', 'E450: buffer number, text or a list required')
  CheckDefAndScriptFailure2(['popup_dialog("a", [1, 2])'], 'E1013: Argument 2: type mismatch, expected dict<any> but got list<number>', 'E715: Dictionary required')
enddef

def Test_popup_locate()
  CheckDefAndScriptFailure2(['popup_locate("a", 20)'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1030: Using a String as a Number')
  CheckDefAndScriptFailure2(['popup_locate(10, "b")'], 'E1013: Argument 2: type mismatch, expected number but got string', 'E1030: Using a String as a Number')
enddef

def Test_popup_menu()
  CheckDefAndScriptFailure2(['popup_menu({"a": 10}, {})'], 'E1013: Argument 1: type mismatch, expected string but got dict<number>', 'E450: buffer number, text or a list required')
  CheckDefAndScriptFailure2(['popup_menu("a", [1, 2])'], 'E1013: Argument 2: type mismatch, expected dict<any> but got list<number>', 'E715: Dictionary required')
enddef

def Test_popup_notification()
  CheckDefAndScriptFailure2(['popup_notification({"a": 10}, {})'], 'E1013: Argument 1: type mismatch, expected string but got dict<number>', 'E450: buffer number, text or a list required')
  CheckDefAndScriptFailure2(['popup_notification("a", [1, 2])'], 'E1013: Argument 2: type mismatch, expected dict<any> but got list<number>', 'E715: Dictionary required')
enddef

def Test_prevnonblank()
  CheckDefFailure(['prevnonblank(null)'], 'E1013: Argument 1: type mismatch, expected string but got special')
  assert_equal(0, prevnonblank(1))
enddef

def Test_prompt_getprompt()
  if has('channel')
    CheckDefFailure(['prompt_getprompt([])'], 'E1013: Argument 1: type mismatch, expected string but got list<unknown>')
    assert_equal('', prompt_getprompt('NonExistingBuf'))
  endif
enddef

def Test_prop_find()
  CheckDefAndScriptFailure2(['prop_find([1, 2])'], 'E1013: Argument 1: type mismatch, expected dict<any> but got list<number>', 'E715: Dictionary required')
  CheckDefAndScriptFailure2(['prop_find([1, 2], "k")'], 'E1013: Argument 1: type mismatch, expected dict<any> but got list<number>', 'E715: Dictionary required')
  CheckDefAndScriptFailure2(['prop_find({"a": 10}, ["a"])'], 'E1013: Argument 2: type mismatch, expected string but got list<string>', 'E730: Using a List as a String')
enddef

def Test_prop_type_add()
  CheckDefAndScriptFailure2(['prop_type_add({"a": 10}, "b")'], 'E1013: Argument 1: type mismatch, expected string but got dict<number>', 'E731: Using a Dictionary as a String')
  CheckDefAndScriptFailure2(['prop_type_add("a", "b")'], 'E1013: Argument 2: type mismatch, expected dict<any> but got string', 'E715: Dictionary required')
enddef

def Test_prop_type_change()
  CheckDefAndScriptFailure2(['prop_type_change({"a": 10}, "b")'], 'E1013: Argument 1: type mismatch, expected string but got dict<number>', 'E731: Using a Dictionary as a String')
  CheckDefAndScriptFailure2(['prop_type_change("a", "b")'], 'E1013: Argument 2: type mismatch, expected dict<any> but got string', 'E715: Dictionary required')
enddef

def Test_prop_type_delete()
  CheckDefAndScriptFailure2(['prop_type_delete({"a": 10})'], 'E1013: Argument 1: type mismatch, expected string but got dict<number>', 'E731: Using a Dictionary as a String')
  CheckDefAndScriptFailure2(['prop_type_delete({"a": 10}, "b")'], 'E1013: Argument 1: type mismatch, expected string but got dict<number>', 'E731: Using a Dictionary as a String')
  CheckDefAndScriptFailure2(['prop_type_delete("a", "b")'], 'E1013: Argument 2: type mismatch, expected dict<any> but got string', 'E715: Dictionary required')
enddef

def Test_prop_type_get()
  CheckDefAndScriptFailure2(['prop_type_get({"a": 10})'], 'E1013: Argument 1: type mismatch, expected string but got dict<number>', 'E731: Using a Dictionary as a String')
  CheckDefAndScriptFailure2(['prop_type_get({"a": 10}, "b")'], 'E1013: Argument 1: type mismatch, expected string but got dict<number>', 'E731: Using a Dictionary as a String')
  CheckDefAndScriptFailure2(['prop_type_get("a", "b")'], 'E1013: Argument 2: type mismatch, expected dict<any> but got string', 'E715: Dictionary required')
enddef

def Test_rand()
  CheckDefFailure(['rand(10)'], 'E1013: Argument 1: type mismatch, expected list<number> but got number')
  CheckDefFailure(['rand(["a"])'], 'E1013: Argument 1: type mismatch, expected list<number> but got list<string>')
  assert_true(rand() >= 0)
  assert_true(rand(srand()) >= 0)
enddef

def Test_range()
  CheckDefAndScriptFailure2(['range("a")'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1030: Using a String as a Number')
  CheckDefAndScriptFailure2(['range(10, "b")'], 'E1013: Argument 2: type mismatch, expected number but got string', 'E1030: Using a String as a Number')
  CheckDefAndScriptFailure2(['range(10, 20, "c")'], 'E1013: Argument 3: type mismatch, expected number but got string', 'E1030: Using a String as a Number')
enddef

def Test_readdir()
   eval expand('sautest')->readdir((e) => e[0] !=# '.')
   eval expand('sautest')->readdirex((e) => e.name[0] !=# '.')
enddef

def Test_readblob()
  var blob = 0z12341234
  writefile(blob, 'Xreadblob')
  var read: blob = readblob('Xreadblob')
  assert_equal(blob, read)

  var lines =<< trim END
      var read: list<string> = readblob('Xreadblob')
  END
  CheckDefAndScriptFailure(lines, 'E1012: Type mismatch; expected list<string> but got blob', 1)
  delete('Xreadblob')
enddef

def Test_readfile()
  var text = ['aaa', 'bbb', 'ccc']
  writefile(text, 'Xreadfile')
  var read: list<string> = readfile('Xreadfile')
  assert_equal(text, read)

  var lines =<< trim END
      var read: dict<string> = readfile('Xreadfile')
  END
  CheckDefAndScriptFailure(lines, 'E1012: Type mismatch; expected dict<string> but got list<string>', 1)
  delete('Xreadfile')

  CheckDefAndScriptFailure2(['readfile("a", 0z10)'], 'E1013: Argument 2: type mismatch, expected string but got blob', 'E976: Using a Blob as a String')
  CheckDefAndScriptFailure2(['readfile("a", "b", "c")'], 'E1013: Argument 3: type mismatch, expected number but got string', 'E1030: Using a String as a Number')
enddef

def Test_reltime()
  CheckFeature reltime

  CheckDefExecAndScriptFailure(['[]->reltime()'], 'E474:')
  CheckDefExecAndScriptFailure(['[]->reltime([])'], 'E474:')

  CheckDefFailure(['reltime("x")'], 'E1013: Argument 1: type mismatch, expected list<number> but got string')
  CheckDefFailure(['reltime(["x", "y"])'], 'E1013: Argument 1: type mismatch, expected list<number> but got list<string>')
  CheckDefFailure(['reltime([1, 2], 10)'], 'E1013: Argument 2: type mismatch, expected list<number> but got number')
  CheckDefFailure(['reltime([1, 2], ["a", "b"])'], 'E1013: Argument 2: type mismatch, expected list<number> but got list<string>')
  var start: list<any> = reltime()
  assert_true(type(reltime(start)) == v:t_list)
  var end: list<any> = reltime()
  assert_true(type(reltime(start, end)) == v:t_list)
enddef

def Test_reltimefloat()
  CheckFeature reltime

  CheckDefExecAndScriptFailure(['[]->reltimefloat()'], 'E474:')

  CheckDefFailure(['reltimefloat("x")'], 'E1013: Argument 1: type mismatch, expected list<number> but got string')
  CheckDefFailure(['reltimefloat([1.1])'], 'E1013: Argument 1: type mismatch, expected list<number> but got list<float>')
  assert_true(type(reltimefloat(reltime())) == v:t_float)
enddef

def Test_reltimestr()
  CheckFeature reltime

  CheckDefExecAndScriptFailure(['[]->reltimestr()'], 'E474:')

  CheckDefFailure(['reltimestr(true)'], 'E1013: Argument 1: type mismatch, expected list<number> but got bool')
  CheckDefFailure(['reltimestr([true])'], 'E1013: Argument 1: type mismatch, expected list<number> but got list<bool>')
  assert_true(type(reltimestr(reltime())) == v:t_string)
enddef

def Test_remote_foreground()
  CheckFeature clientserver
  # remote_foreground() doesn't fail on MS-Windows
  CheckNotMSWindows
  CheckEnv DISPLAY

  CheckDefFailure(['remote_foreground(10)'], 'E1013: Argument 1: type mismatch, expected string but got number')
  assert_fails('remote_foreground("NonExistingServer")', 'E241:')
enddef

def Test_remote_peek()
  CheckFeature clientserver
  CheckEnv DISPLAY
  CheckDefAndScriptFailure2(['remote_peek(0z10)'], 'E1013: Argument 1: type mismatch, expected string but got blob', 'E976: Using a Blob as a String')
  CheckDefAndScriptFailure2(['remote_peek("a5b6c7", [1])'], 'E1013: Argument 2: type mismatch, expected string but got list<number>', 'E573: Invalid server id used')
enddef

def Test_remote_startserver()
  CheckFeature clientserver
  CheckEnv DISPLAY
  CheckDefFailure(['remote_startserver({})'], 'E1013: Argument 1: type mismatch, expected string but got dict<unknown>')
enddef

def Test_remove_return_type()
  var l = remove({one: [1, 2], two: [3, 4]}, 'one')
  var res = 0
  for n in l
    res += n
  endfor
  res->assert_equal(3)
enddef

def Test_rename()
  CheckDefFailure(['rename(1, "b")'], 'E1013: Argument 1: type mismatch, expected string but got number')
  CheckDefFailure(['rename("a", 2)'], 'E1013: Argument 2: type mismatch, expected string but got number')
enddef

def Test_resolve()
  CheckDefFailure(['resolve([])'], 'E1013: Argument 1: type mismatch, expected string but got list<unknown>')
  assert_equal('SomeFile', resolve('SomeFile'))
enddef

def Test_reverse()
  CheckDefAndScriptFailure2(['reverse(10)'], 'E1013: Argument 1: type mismatch, expected list<any> but got number', 'E899: Argument of reverse() must be a List or Blob')
  CheckDefAndScriptFailure2(['reverse("abc")'], 'E1013: Argument 1: type mismatch, expected list<any> but got string', 'E899: Argument of reverse() must be a List or Blob')
enddef

def Test_reverse_return_type()
  var l = reverse([1, 2, 3])
  var res = 0
  for n in l
    res += n
  endfor
  res->assert_equal(6)
enddef

def Test_screenattr()
  CheckDefFailure(['screenattr("x", 1)'], 'E1013: Argument 1: type mismatch, expected number but got string')
  CheckDefFailure(['screenattr(1, "x")'], 'E1013: Argument 2: type mismatch, expected number but got string')
enddef

def Test_screenchar()
  CheckDefFailure(['screenchar("x", 1)'], 'E1013: Argument 1: type mismatch, expected number but got string')
  CheckDefFailure(['screenchar(1, "x")'], 'E1013: Argument 2: type mismatch, expected number but got string')
enddef

def Test_screenchars()
  CheckDefFailure(['screenchars("x", 1)'], 'E1013: Argument 1: type mismatch, expected number but got string')
  CheckDefFailure(['screenchars(1, "x")'], 'E1013: Argument 2: type mismatch, expected number but got string')
enddef

def Test_screenpos()
  CheckDefFailure(['screenpos("a", 1, 1)'], 'E1013: Argument 1: type mismatch, expected number but got string')
  CheckDefFailure(['screenpos(1, "b", 1)'], 'E1013: Argument 2: type mismatch, expected number but got string')
  CheckDefFailure(['screenpos(1, 1, "c")'], 'E1013: Argument 3: type mismatch, expected number but got string')
  assert_equal({col: 1, row: 1, endcol: 1, curscol: 1}, screenpos(1, 1, 1))
enddef

def Test_screenstring()
  CheckDefFailure(['screenstring("x", 1)'], 'E1013: Argument 1: type mismatch, expected number but got string')
  CheckDefFailure(['screenstring(1, "x")'], 'E1013: Argument 2: type mismatch, expected number but got string')
enddef

def Test_search()
  new
  setline(1, ['foo', 'bar'])
  var val = 0
  # skip expr returns boolean
  search('bar', 'W', 0, 0, () => val == 1)->assert_equal(2)
  :1
  search('bar', 'W', 0, 0, () => val == 0)->assert_equal(0)
  # skip expr returns number, only 0 and 1 are accepted
  :1
  search('bar', 'W', 0, 0, () => 0)->assert_equal(2)
  :1
  search('bar', 'W', 0, 0, () => 1)->assert_equal(0)
  assert_fails("search('bar', '', 0, 0, () => -1)", 'E1023:')
  assert_fails("search('bar', '', 0, 0, () => -1)", 'E1023:')

  setline(1, "find this word")
  normal gg
  var col = 7
  assert_equal(1, search('this', '', 0, 0, 'col(".") > col'))
  normal 0
  assert_equal([1, 6], searchpos('this', '', 0, 0, 'col(".") > col'))

  col = 5
  normal 0
  assert_equal(0, search('this', '', 0, 0, 'col(".") > col'))
  normal 0
  assert_equal([0, 0], searchpos('this', '', 0, 0, 'col(".") > col'))
  bwipe!
enddef

def Test_searchcount()
  new
  setline(1, "foo bar")
  :/foo
  searchcount({recompute: true})
      ->assert_equal({
          exact_match: 1,
          current: 1,
          total: 1,
          maxcount: 99,
          incomplete: 0})
  bwipe!
enddef

def Test_searchpair()
  new
  setline(1, "here { and } there")

  normal f{
  var col = 15
  assert_equal(1, searchpair('{', '', '}', '', 'col(".") > col'))
  assert_equal(12, col('.'))
  normal 0f{
  assert_equal([1, 12], searchpairpos('{', '', '}', '', 'col(".") > col'))

  col = 8
  normal 0f{
  assert_equal(0, searchpair('{', '', '}', '', 'col(".") > col'))
  assert_equal(6, col('.'))
  normal 0f{
  assert_equal([0, 0], searchpairpos('{', '', '}', '', 'col(".") > col'))

  var lines =<< trim END
      vim9script
      setline(1, '()')
      normal gg
      def Fail()
        try
          searchpairpos('(', '', ')', 'nW', '[0]->map("")')
        catch
          g:caught = 'yes'
        endtry
      enddef
      Fail()
  END
  CheckScriptSuccess(lines)
  assert_equal('yes', g:caught)

  unlet g:caught
  bwipe!
enddef

def Test_server2client()
  CheckFeature clientserver
  CheckEnv DISPLAY
  CheckDefAndScriptFailure2(['server2client(10, "b")'], 'E1013: Argument 1: type mismatch, expected string but got number', 'E573: Invalid server id used:')
  CheckDefAndScriptFailure2(['server2client("a", 10)'], 'E1013: Argument 2: type mismatch, expected string but got number', 'E573: Invalid server id used:')
enddef

def Test_set_get_bufline()
  # similar to Test_setbufline_getbufline()
  var lines =<< trim END
      new
      var b = bufnr('%')
      hide
      assert_equal(0, setbufline(b, 1, ['foo', 'bar']))
      assert_equal(['foo'], getbufline(b, 1))
      assert_equal(['bar'], getbufline(b, '$'))
      assert_equal(['foo', 'bar'], getbufline(b, 1, 2))
      exe "bd!" b
      assert_equal([], getbufline(b, 1, 2))

      split Xtest
      setline(1, ['a', 'b', 'c'])
      b = bufnr('%')
      wincmd w

      assert_equal(1, setbufline(b, 5, 'x'))
      assert_equal(1, setbufline(b, 5, ['x']))
      assert_equal(1, setbufline(b, 5, []))
      assert_equal(1, setbufline(b, 5, test_null_list()))

      assert_equal(1, 'x'->setbufline(bufnr('$') + 1, 1))
      assert_equal(1, ['x']->setbufline(bufnr('$') + 1, 1))
      assert_equal(1, []->setbufline(bufnr('$') + 1, 1))
      assert_equal(1, test_null_list()->setbufline(bufnr('$') + 1, 1))

      assert_equal(['a', 'b', 'c'], getbufline(b, 1, '$'))

      assert_equal(0, setbufline(b, 4, ['d', 'e']))
      assert_equal(['c'], b->getbufline(3))
      assert_equal(['d'], getbufline(b, 4))
      assert_equal(['e'], getbufline(b, 5))
      assert_equal([], getbufline(b, 6))
      assert_equal([], getbufline(b, 2, 1))

      if has('job')
        setbufline(b, 2, [function('eval'), {key: 123}, string(test_null_job())])
        assert_equal(["function('eval')",
                        "{'key': 123}",
                        "no process"],
                        getbufline(b, 2, 4))
      endif

      exe 'bwipe! ' .. b
  END
  CheckDefAndScriptSuccess(lines)
enddef

def Test_searchdecl()
  searchdecl('blah', true, true)->assert_equal(1)
enddef

def Test_setbufvar()
  setbufvar(bufnr('%'), '&syntax', 'vim')
  &syntax->assert_equal('vim')
  setbufvar(bufnr('%'), '&ts', 16)
  &ts->assert_equal(16)
  setbufvar(bufnr('%'), '&ai', true)
  &ai->assert_equal(true)
  setbufvar(bufnr('%'), '&ft', 'filetype')
  &ft->assert_equal('filetype')

  settabwinvar(1, 1, '&syntax', 'vam')
  &syntax->assert_equal('vam')
  settabwinvar(1, 1, '&ts', 15)
  &ts->assert_equal(15)
  setlocal ts=8
  settabwinvar(1, 1, '&list', false)
  &list->assert_equal(false)
  settabwinvar(1, 1, '&list', true)
  &list->assert_equal(true)
  setlocal list&

  setbufvar('%', 'myvar', 123)
  getbufvar('%', 'myvar')->assert_equal(123)
enddef

def Test_setcharsearch()
  CheckDefFailure(['setcharsearch("x")'], 'E1013: Argument 1: type mismatch, expected dict<any> but got string')
  CheckDefFailure(['setcharsearch([])'], 'E1013: Argument 1: type mismatch, expected dict<any> but got list<unknown>')
  var d: dict<any> = {char: 'x', forward: 1, until: 1}
  setcharsearch(d)
  assert_equal(d, getcharsearch())
enddef

def Test_setcmdpos()
  CheckDefFailure(['setcmdpos("x")'], 'E1013: Argument 1: type mismatch, expected number but got string')
enddef

def Test_setfperm()
  CheckDefFailure(['setfperm(1, "b")'], 'E1013: Argument 1: type mismatch, expected string but got number')
  CheckDefFailure(['setfperm("a", 0z10)'], 'E1013: Argument 2: type mismatch, expected string but got blob')
enddef

def Test_setline()
  new
  setline(1, range(1, 4))
  assert_equal(['1', '2', '3', '4'], getline(1, '$'))
  setline(1, ['a', 'b', 'c', 'd'])
  assert_equal(['a', 'b', 'c', 'd'], getline(1, '$'))
  setline(1, 'one')
  assert_equal(['one', 'b', 'c', 'd'], getline(1, '$'))
  bw!
enddef

def Test_setloclist()
  var items = [{filename: '/tmp/file', lnum: 1, valid: true}]
  var what = {items: items}
  setqflist([], ' ', what)
  setloclist(0, [], ' ', what)
enddef

def Test_setreg()
  setreg('a', ['aaa', 'bbb', 'ccc'])
  var reginfo = getreginfo('a')
  setreg('a', reginfo)
  getreginfo('a')->assert_equal(reginfo)
  assert_fails('setreg("ab", 0)', 'E1162:')
enddef 

def Test_sha256()
  CheckDefFailure(['sha256(100)'], 'E1013: Argument 1: type mismatch, expected string but got number')
  CheckDefFailure(['sha256(0zABCD)'], 'E1013: Argument 1: type mismatch, expected string but got blob')
  assert_equal('ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad', sha256('abc'))
enddef

def Test_shiftwidth()
  CheckDefFailure(['shiftwidth("x")'], 'E1013: Argument 1: type mismatch, expected number but got string')
enddef

def Test_sign_define()
  CheckDefAndScriptFailure2(['sign_define({"a": 10})'], 'E1013: Argument 1: type mismatch, expected string but got dict<number>', 'E731: Using a Dictionary as a String')
  CheckDefAndScriptFailure2(['sign_define({"a": 10}, "b")'], 'E1013: Argument 1: type mismatch, expected string but got dict<number>', 'E731: Using a Dictionary as a String')
  CheckDefAndScriptFailure2(['sign_define("a", ["b"])'], 'E1013: Argument 2: type mismatch, expected dict<any> but got list<string>', 'E715: Dictionary required')
enddef

def Test_sign_undefine()
  CheckDefAndScriptFailure2(['sign_undefine({})'], 'E1013: Argument 1: type mismatch, expected string but got dict<unknown>', 'E731: Using a Dictionary as a String')
  CheckDefAndScriptFailure2(['sign_undefine([1])'], 'E1013: Argument 1: type mismatch, expected list<string> but got list<number>', 'E155: Unknown sign:')
enddef

def Test_sign_unplace()
  CheckDefAndScriptFailure2(['sign_unplace({"a": 10})'], 'E1013: Argument 1: type mismatch, expected string but got dict<number>', 'E474: Invalid argument')
  CheckDefAndScriptFailure2(['sign_unplace({"a": 10}, "b")'], 'E1013: Argument 1: type mismatch, expected string but got dict<number>', 'E474: Invalid argument')
  CheckDefAndScriptFailure2(['sign_unplace("a", ["b"])'], 'E1013: Argument 2: type mismatch, expected dict<any> but got list<string>', 'E715: Dictionary required')
enddef

def Test_simplify()
  CheckDefFailure(['simplify(100)'], 'E1013: Argument 1: type mismatch, expected string but got number')
  call assert_equal('NonExistingFile', simplify('NonExistingFile'))
enddef

def Test_slice()
  assert_equal('12345', slice('012345', 1))
  assert_equal('123', slice('012345', 1, 4))
  assert_equal('1234', slice('012345', 1, -1))
  assert_equal('1', slice('012345', 1, -4))
  assert_equal('', slice('012345', 1, -5))
  assert_equal('', slice('012345', 1, -6))

  assert_equal([1, 2, 3, 4, 5], slice(range(6), 1))
  assert_equal([1, 2, 3], slice(range(6), 1, 4))
  assert_equal([1, 2, 3, 4], slice(range(6), 1, -1))
  assert_equal([1], slice(range(6), 1, -4))
  assert_equal([], slice(range(6), 1, -5))
  assert_equal([], slice(range(6), 1, -6))

  assert_equal(0z1122334455, slice(0z001122334455, 1))
  assert_equal(0z112233, slice(0z001122334455, 1, 4))
  assert_equal(0z11223344, slice(0z001122334455, 1, -1))
  assert_equal(0z11, slice(0z001122334455, 1, -4))
  assert_equal(0z, slice(0z001122334455, 1, -5))
  assert_equal(0z, slice(0z001122334455, 1, -6))
enddef

def Test_spellsuggest()
  if !has('spell')
    MissingFeature 'spell'
  else
    spellsuggest('marrch', 1, true)->assert_equal(['March'])
  endif
enddef

def Test_sound_stop()
  CheckFeature sound
  CheckDefFailure(['sound_stop("x")'], 'E1013: Argument 1: type mismatch, expected number but got string')
enddef

def Test_soundfold()
  CheckDefFailure(['soundfold(20)'], 'E1013: Argument 1: type mismatch, expected string but got number')
  assert_equal('abc', soundfold('abc'))
enddef

def Test_sort_return_type()
  var res: list<number>
  res = [1, 2, 3]->sort()
enddef

def Test_sort_argument()
  var lines =<< trim END
    var res = ['b', 'a', 'c']->sort('i')
    res->assert_equal(['a', 'b', 'c'])

    def Compare(a: number, b: number): number
      return a - b
    enddef
    var l = [3, 6, 7, 1, 8, 2, 4, 5]
    sort(l, Compare)
    assert_equal([1, 2, 3, 4, 5, 6, 7, 8], l)
  END
  CheckDefAndScriptSuccess(lines)
enddef

def Test_spellbadword()
  CheckDefFailure(['spellbadword(100)'], 'E1013: Argument 1: type mismatch, expected string but got number')
  spellbadword('good')->assert_equal(['', ''])
enddef

def Test_split()
  split('  aa  bb  ', '\W\+', true)->assert_equal(['', 'aa', 'bb', ''])
enddef

def Test_srand()
  CheckDefFailure(['srand("a")'], 'E1013: Argument 1: type mismatch, expected number but got string')
  type(srand(100))->assert_equal(v:t_list)
enddef

def Test_state()
  CheckDefFailure(['state({})'], 'E1013: Argument 1: type mismatch, expected string but got dict<unknown>')
  assert_equal('', state('a'))
enddef

def Run_str2float()
  if !has('float')
    MissingFeature 'float'
  endif
    str2float("1.00")->assert_equal(1.00)
    str2float("2e-2")->assert_equal(0.02)

    CheckDefFailure(['str2float(123)'], 'E1013:')
    CheckScriptFailure(['vim9script', 'echo str2float(123)'], 'E1024:')
  endif
enddef

def Test_str2nr()
  str2nr("1'000'000", 10, true)->assert_equal(1000000)

  CheckDefFailure(['str2nr(123)'], 'E1013:')
  CheckScriptFailure(['vim9script', 'echo str2nr(123)'], 'E1024:')
  CheckDefFailure(['str2nr("123", "x")'], 'E1013:')
  CheckScriptFailure(['vim9script', 'echo str2nr("123", "x")'], 'E1030:')
  CheckDefFailure(['str2nr("123", 10, "x")'], 'E1013:')
  CheckScriptFailure(['vim9script', 'echo str2nr("123", 10, "x")'], 'E1135:')
enddef

def Test_strchars()
  strchars("A\u20dd", true)->assert_equal(1)
enddef

def Test_stridx()
  CheckDefAndScriptFailure2(['stridx([1], "b")'], 'E1013: Argument 1: type mismatch, expected string but got list<number>', 'E730: Using a List as a String')
  CheckDefAndScriptFailure2(['stridx("a", {})'], 'E1013: Argument 2: type mismatch, expected string but got dict<unknown>', 'E731: Using a Dictionary as a String')
  CheckDefAndScriptFailure2(['stridx("a", "b", "c")'], 'E1013: Argument 3: type mismatch, expected number but got string', 'E1030: Using a String as a Number')
enddef

def Test_strlen()
  CheckDefFailure(['strlen([])'], 'E1013: Argument 1: type mismatch, expected string but got list<unknown>')
  "abc"->strlen()->assert_equal(3)
  strlen(99)->assert_equal(2)
enddef

def Test_strptime()
  CheckFunction strptime
  CheckDefFailure(['strptime(10, "2021")'], 'E1013: Argument 1: type mismatch, expected string but got number')
  CheckDefFailure(['strptime("%Y", 2021)'], 'E1013: Argument 2: type mismatch, expected string but got number')
  # BUG: Directly calling strptime() in this function gives an "E117: Unknown
  # function" error on MS-Windows even with the above CheckFunction call for
  # strptime().
  #assert_true(strptime('%Y', '2021') != 0)
enddef

def Test_strridx()
  CheckDefAndScriptFailure2(['strridx([1], "b")'], 'E1013: Argument 1: type mismatch, expected string but got list<number>', 'E730: Using a List as a String')
  CheckDefAndScriptFailure2(['strridx("a", {})'], 'E1013: Argument 2: type mismatch, expected string but got dict<unknown>', 'E731: Using a Dictionary as a String')
  CheckDefAndScriptFailure2(['strridx("a", "b", "c")'], 'E1013: Argument 3: type mismatch, expected number but got string', 'E1030: Using a String as a Number')
enddef

def Test_strtrans()
  CheckDefFailure(['strtrans(20)'], 'E1013: Argument 1: type mismatch, expected string but got number')
  assert_equal('abc', strtrans('abc'))
enddef

def Test_strwidth()
  CheckDefFailure(['strwidth(10)'], 'E1013: Argument 1: type mismatch, expected string but got number')
  CheckScriptFailure(['vim9script', 'echo strwidth(10)'], 'E1024:')
  assert_equal(4, strwidth('abcd'))
enddef

def Test_submatch()
  var pat = 'A\(.\)\(.\)\(.\)\(.\)\(.\)\(.\)\(.\)\(.\)\(.\)'
  var Rep = () => range(10)->mapnew((_, v) => submatch(v, true))->string()
  var actual = substitute('A123456789', pat, Rep, '')
  var expected = "[['A123456789'], ['1'], ['2'], ['3'], ['4'], ['5'], ['6'], ['7'], ['8'], ['9']]"
  actual->assert_equal(expected)
enddef

def Test_substitute()
  var res = substitute('A1234', '\d', 'X', '')
  assert_equal('AX234', res)

  if has('job')
    assert_fails('"text"->substitute(".*", () => job_start(":"), "")', 'E908: using an invalid value as a String: job')
    assert_fails('"text"->substitute(".*", () => job_start(":")->job_getchannel(), "")', 'E908: using an invalid value as a String: channel')
  endif
enddef

def Test_swapinfo()
  CheckDefFailure(['swapinfo({})'], 'E1013: Argument 1: type mismatch, expected string but got dict<unknown>')
  call assert_equal({error: 'Cannot open file'}, swapinfo('x'))
enddef

def Test_swapname()
  CheckDefFailure(['swapname([])'], 'E1013: Argument 1: type mismatch, expected string but got list<unknown>')
  assert_fails('swapname("NonExistingBuf")', 'E94:')
enddef

def Test_synID()
  new
  setline(1, "text")
  synID(1, 1, true)->assert_equal(0)
  bwipe!
enddef

def Test_synIDtrans()
  CheckDefFailure(['synIDtrans("a")'], 'E1013: Argument 1: type mismatch, expected number but got string')
enddef

def Test_tabpagebuflist()
  CheckDefFailure(['tabpagebuflist("t")'], 'E1013: Argument 1: type mismatch, expected number but got string')
  assert_equal([bufnr('')], tabpagebuflist())
  assert_equal([bufnr('')], tabpagebuflist(1))
enddef

def Test_tabpagenr()
  CheckDefAndScriptFailure2(['tabpagenr(1)'], 'E1013: Argument 1: type mismatch, expected string but got number', 'E15: Invalid expression:')
  assert_equal(1, tabpagenr('$'))
  assert_equal(1, tabpagenr())
enddef

def Test_taglist()
  CheckDefAndScriptFailure2(['taglist([1])'], 'E1013: Argument 1: type mismatch, expected string but got list<number>', 'E730: Using a List as a String')
  CheckDefAndScriptFailure2(['taglist("a", [2])'], 'E1013: Argument 2: type mismatch, expected string but got list<number>', 'E730: Using a List as a String')
enddef

def Test_term_dumpload()
  CheckRunVimInTerminal
  CheckDefAndScriptFailure2(['term_dumpload({"a": 10})'], 'E1013: Argument 1: type mismatch, expected string but got dict<number>', 'E1174: String required for argument 1')
  CheckDefAndScriptFailure2(['term_dumpload({"a": 10}, "b")'], 'E1013: Argument 1: type mismatch, expected string but got dict<number>', 'E1174: String required for argument 1')
  CheckDefAndScriptFailure2(['term_dumpload("a", ["b"])'], 'E1013: Argument 2: type mismatch, expected dict<any> but got list<string>', 'E1206: Dictionary required for argument 2')
enddef

def Test_term_getaltscreen()
  CheckRunVimInTerminal
  CheckDefAndScriptFailure2(['term_getaltscreen(true)'], 'E1013: Argument 1: type mismatch, expected string but got bool', 'E1138: Using a Bool as a Number')
enddef

def Test_term_getansicolors()
  CheckRunVimInTerminal
  CheckFeature termguicolors
  CheckDefAndScriptFailure2(['term_getansicolors(["a"])'], 'E1013: Argument 1: type mismatch, expected string but got list<string>', 'E745: Using a List as a Number')
enddef

def Test_term_getcursor()
  CheckRunVimInTerminal
  CheckDefAndScriptFailure2(['term_getcursor({"a": 10})'], 'E1013: Argument 1: type mismatch, expected string but got dict<number>', 'E728: Using a Dictionary as a Number')
enddef

def Test_term_getjob()
  CheckRunVimInTerminal
  CheckDefAndScriptFailure2(['term_getjob(0z10)'], 'E1013: Argument 1: type mismatch, expected string but got blob', 'E974: Using a Blob as a Number')
enddef

def Test_term_getscrolled()
  CheckRunVimInTerminal
  CheckDefAndScriptFailure2(['term_getscrolled(1.1)'], 'E1013: Argument 1: type mismatch, expected string but got float', 'E805: Using a Float as a Number')
enddef

def Test_term_getsize()
  CheckRunVimInTerminal
  CheckDefAndScriptFailure2(['term_getsize(1.1)'], 'E1013: Argument 1: type mismatch, expected string but got float', 'E805: Using a Float as a Number')
enddef

def Test_term_getstatus()
  CheckRunVimInTerminal
  CheckDefAndScriptFailure2(['term_getstatus(1.1)'], 'E1013: Argument 1: type mismatch, expected string but got float', 'E805: Using a Float as a Number')
enddef

def Test_term_gettitle()
  CheckRunVimInTerminal
  CheckDefAndScriptFailure2(['term_gettitle(1.1)'], 'E1013: Argument 1: type mismatch, expected string but got float', 'E805: Using a Float as a Number')
enddef

def Test_term_gettty()
  if !has('terminal')
    MissingFeature 'terminal'
  else
    var buf = Run_shell_in_terminal({})
    term_gettty(buf, true)->assert_notequal('')
    StopShellInTerminal(buf)
  endif
enddef

def Test_term_start()
  if !has('terminal')
    MissingFeature 'terminal'
  else
    botright new
    var winnr = winnr()
    term_start(&shell, {curwin: true})
    winnr()->assert_equal(winnr)
    bwipe!
  endif
enddef

def Test_test_alloc_fail()
  CheckDefAndScriptFailure2(['test_alloc_fail("a", 10, 20)'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E474: Invalid argument')
  CheckDefAndScriptFailure2(['test_alloc_fail(10, "b", 20)'], 'E1013: Argument 2: type mismatch, expected number but got string', 'E474: Invalid argument')
  CheckDefAndScriptFailure2(['test_alloc_fail(10, 20, "c")'], 'E1013: Argument 3: type mismatch, expected number but got string', 'E474: Invalid argument')
enddef

def Test_test_feedinput()
  CheckDefAndScriptFailure2(['test_feedinput(test_void())'], 'E1013: Argument 1: type mismatch, expected string but got void', 'E1031: Cannot use void value')
  CheckDefAndScriptFailure2(['test_feedinput(["a"])'], 'E1013: Argument 1: type mismatch, expected string but got list<string>', 'E730: Using a List as a String')
enddef

def Test_test_getvalue()
  CheckDefAndScriptFailure2(['test_getvalue(1.1)'], 'E1013: Argument 1: type mismatch, expected string but got float', 'E474: Invalid argument')
enddef

def Test_test_ignore_error()
  CheckDefAndScriptFailure2(['test_ignore_error([])'], 'E1013: Argument 1: type mismatch, expected string but got list<unknown>', 'E474: Invalid argument')
  test_ignore_error('RESET')
enddef

def Test_test_option_not_set()
  CheckDefAndScriptFailure2(['test_option_not_set([])'], 'E1013: Argument 1: type mismatch, expected string but got list<unknown>', 'E474: Invalid argument')
enddef

def Test_test_setmouse()
  CheckDefAndScriptFailure2(['test_setmouse("a", 10)'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E474: Invalid argument')
  CheckDefAndScriptFailure2(['test_setmouse(10, "b")'], 'E1013: Argument 2: type mismatch, expected number but got string', 'E474: Invalid argument')
enddef

def Test_test_settime()
  CheckDefAndScriptFailure2(['test_settime([1])'], 'E1013: Argument 1: type mismatch, expected number but got list<number>', 'E745: Using a List as a Number')
enddef

def Test_test_srand_seed()
  CheckDefAndScriptFailure2(['test_srand_seed([1])'], 'E1013: Argument 1: type mismatch, expected number but got list<number>', 'E745: Using a List as a Number')
  CheckDefAndScriptFailure2(['test_srand_seed("10")'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1030: Using a String as a Number')
enddef

def Test_timer_info()
  CheckDefFailure(['timer_info("id")'], 'E1013: Argument 1: type mismatch, expected number but got string')
  assert_equal([], timer_info(100))
  assert_equal([], timer_info())
enddef

def Test_timer_paused()
  var id = timer_start(50, () => 0)
  timer_pause(id, true)
  var info = timer_info(id)
  info[0]['paused']->assert_equal(1)
  timer_stop(id)
enddef

def Test_timer_stop()
  CheckDefFailure(['timer_stop("x")'], 'E1013: Argument 1: type mismatch, expected number but got string')
  assert_equal(0, timer_stop(100))
enddef

def Test_tolower()
  CheckDefFailure(['tolower(1)'], 'E1013: Argument 1: type mismatch, expected string but got number')
enddef

def Test_toupper()
  CheckDefFailure(['toupper(1)'], 'E1013: Argument 1: type mismatch, expected string but got number')
enddef

def Test_tr()
  CheckDefFailure(['tr(1, "a", "b")'], 'E1013: Argument 1: type mismatch, expected string but got number')
  CheckDefFailure(['tr("a", 1, "b")'], 'E1013: Argument 2: type mismatch, expected string but got number')
  CheckDefFailure(['tr("a", "a", 1)'], 'E1013: Argument 3: type mismatch, expected string but got number')
enddef

def Test_trim()
  CheckDefAndScriptFailure2(['trim(["a"])'], 'E1013: Argument 1: type mismatch, expected string but got list<string>', 'E730: Using a List as a String')
  CheckDefAndScriptFailure2(['trim("a", ["b"])'], 'E1013: Argument 2: type mismatch, expected string but got list<string>', 'E730: Using a List as a String')
  CheckDefAndScriptFailure2(['trim("a", "b", "c")'], 'E1013: Argument 3: type mismatch, expected number but got string', 'E1030: Using a String as a Number')
enddef

def Test_typename()
  if has('float')
    assert_equal('func([unknown], [unknown]): float', typename(function('pow')))
  endif
enddef

def Test_undofile()
  CheckDefFailure(['undofile(10)'], 'E1013: Argument 1: type mismatch, expected string but got number')
  assert_equal('.abc.un~', fnamemodify(undofile('abc'), ':t'))
enddef

def Test_values()
  CheckDefFailure(['values([])'], 'E1013: Argument 1: type mismatch, expected dict<any> but got list<unknown>')
  assert_equal([], {}->values())
  assert_equal(['sun'], {star: 'sun'}->values())
enddef

def Test_virtcol()
  CheckDefAndScriptFailure2(['virtcol(1.1)'], 'E1013: Argument 1: type mismatch, expected string but got float', 'E1174: String required for argument 1')
  new
  setline(1, ['abcdefgh'])
  cursor(1, 4)
  assert_equal(4, virtcol('.'))
  assert_equal(4, virtcol([1, 4]))
  assert_equal(9, virtcol([1, '$']))
  assert_equal(0, virtcol([10, '$']))
  bw!
enddef

def Test_win_execute()
  assert_equal("\n" .. winnr(), win_execute(win_getid(), 'echo winnr()'))
  assert_equal("\n" .. winnr(), 'echo winnr()'->win_execute(win_getid()))
  assert_equal("\n" .. winnr(), win_execute(win_getid(), 'echo winnr()', 'silent'))
  assert_equal('', win_execute(342343, 'echo winnr()'))
enddef

def Test_win_findbuf()
  CheckDefFailure(['win_findbuf("a")'], 'E1013: Argument 1: type mismatch, expected number but got string')
  assert_equal([], win_findbuf(1000))
  assert_equal([win_getid()], win_findbuf(bufnr('')))
enddef

def Test_win_getid()
  CheckDefFailure(['win_getid(".")'], 'E1013: Argument 1: type mismatch, expected number but got string')
  CheckDefFailure(['win_getid(1, ".")'], 'E1013: Argument 2: type mismatch, expected number but got string')
  assert_equal(win_getid(), win_getid(1, 1))
enddef

def Test_win_splitmove()
  split
  win_splitmove(1, 2, {vertical: true, rightbelow: true})
  close
enddef

def Test_winnr()
  CheckDefFailure(['winnr([])'], 'E1013: Argument 1: type mismatch, expected string but got list<unknown>')
  assert_equal(1, winnr())
  assert_equal(1, winnr('$'))
enddef

def Test_winrestcmd()
  split
  var cmd = winrestcmd()
  wincmd _
  exe cmd
  assert_equal(cmd, winrestcmd())
  close
enddef

def Test_winrestview()
  CheckDefFailure(['winrestview([])'], 'E1013: Argument 1: type mismatch, expected dict<any> but got list<unknown>')
  :%d _
  setline(1, 'Hello World')
  winrestview({lnum: 1, col: 6})
  assert_equal([1, 7], [line('.'), col('.')])
enddef

def Test_winsaveview()
  var view: dict<number> = winsaveview()

  var lines =<< trim END
      var view: list<number> = winsaveview()
  END
  CheckDefAndScriptFailure(lines, 'E1012: Type mismatch; expected list<number> but got dict<number>', 1)
enddef

def Test_win_gettype()
  CheckDefAndScriptFailure2(['win_gettype("x")'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1030: Using a String as a Number')
enddef

def Test_win_gotoid()
  CheckDefAndScriptFailure2(['win_gotoid("x")'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1030: Using a String as a Number')
enddef

def Test_win_id2tabwin()
  CheckDefAndScriptFailure2(['win_id2tabwin("x")'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1030: Using a String as a Number')
enddef

def Test_win_id2win()
  CheckDefAndScriptFailure2(['win_id2win("x")'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1030: Using a String as a Number')
enddef

def Test_win_screenpos()
  CheckDefAndScriptFailure2(['win_screenpos("x")'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1030: Using a String as a Number')
enddef

def Test_winbufnr()
  CheckDefAndScriptFailure2(['winbufnr("x")'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1030: Using a String as a Number')
enddef

def Test_winheight()
  CheckDefAndScriptFailure2(['winheight("x")'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1030: Using a String as a Number')
enddef

def Test_winlayout()
  CheckDefAndScriptFailure2(['winlayout("x")'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1030: Using a String as a Number')
enddef

def Test_winwidth()
  CheckDefAndScriptFailure2(['winwidth("x")'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1030: Using a String as a Number')
enddef

def Test_xor()
  CheckDefAndScriptFailure2(['xor("x", 0x2)'], 'E1013: Argument 1: type mismatch, expected number but got string', 'E1030: Using a String as a Number')
  CheckDefAndScriptFailure2(['xor(0x1, "x")'], 'E1013: Argument 2: type mismatch, expected number but got string', 'E1030: Using a String as a Number')
enddef

" vim: ts=8 sw=2 sts=2 expandtab tw=80 fdm=marker
