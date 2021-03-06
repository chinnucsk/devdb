#   Copyright 2007-2008 Konrad-Zuse-Zentrum für Informationstechnik Berlin
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

AC_PREREQ(2.65)
AC_INIT(scalaris, 0.2, schuett@zib.de)

###########################################################
#
# check tokyo cabinet and toke
#
###########################################################

ENABLE_TOKE=
TOKEPREFIX=
AC_ARG_ENABLE([toke], AS_HELP_STRING([--disable-toke], [disable support for tokyo cabinet through toke]), [TOKEPREFIX=no])
AC_ARG_ENABLE([toke],
              AS_HELP_STRING([--enable-toke@<:@=DIR@:>@],
              [enable support for tokyo cabinet through toke]),
              [ENABLE_TOKE=yes
               TOKEPREFIX=$enableval])

###########################################################
#
# check browser for 'make test-vts'
#
###########################################################

AC_ARG_WITH([browser],
            [AS_HELP_STRING([--with-browser=BROWSER],
               [use the given browser for 'make test-vts' (default is xdg-open)])],
            [with_browser=$withval],
            [with_browser=xdg-open])

AC_PATH_PROG([BROWSER], [$with_browser], [$with_browser])
AS_IF([test "x$BROWSER" = x],
      [AC_MSG_WARN([--with-browser was given, but "$with_browser" was not found ('make test-vts' will likely fail)])])

###########################################################
#
# check erlang
#
###########################################################
AC_LANG_ERLANG

AC_ERLANG_NEED_ERLC
AC_ERLANG_NEED_ERL

AC_ERLANG_SUBST_ROOT_DIR
AC_ERLANG_SUBST_LIB_DIR

AC_CACHE_CHECK([for Erlang/OTP ERTS version],
    [erlang_cv_erts_ver],
    [AC_LANG_PUSH([Erlang])[]dnl
     AC_RUN_IFELSE(
        [AC_LANG_PROGRAM([], [dnl
            Version = erlang:system_info(version),
            file:write_file("conftest.out", Version),
            ReturnValue = 0,
            halt(ReturnValue)])],
        [erlang_cv_erts_ver=`cat conftest.out`],
        [AC_MSG_FAILURE([test Erlang program execution failed])])
     AC_LANG_POP([Erlang])[]dnl
    ])
AC_SUBST([ERLANG_ERTS_VER], [$erlang_cv_erts_ver])

ERLANG_TOKE_FLAGS=
AS_IF([test "x$TOKEPREFIX" != xno],
            [
            ERLANG_TOKE_MESSAGE=
            AS_IF([test "x$TOKEPREFIX" != x], [export ERL_LIBS="$TOKEPREFIX"])
            AC_ERLANG_CHECK_LIB(toke,
              [AC_CHECK_FILE($ERLANG_LIB_DIR_toke/priv/libtoke.so,
                [HAVETOKE=", {d, have_toke}"
                 HAVETOKE_DIALYZER="-Dhave_toke"
                 ERLANG_TOKE_FLAGS="-pa $ERLANG_LIB_DIR_toke/ebin"
                ],
                [HAVETOKE=""
                 HAVETOKE_DIALYZER=""
                 ERLANG_TOKE_MESSAGE="toke library libtoke.so not found"
                ])
              ],
              [HAVETOKE=""
               HAVETOKE_DIALYZER=""
               ERLANG_TOKE_MESSAGE="toke erlang library not found"
              ])
            AS_IF([test "x$TOKEPREFIX" != x], [export ERL_LIBS=""])
            AS_IF([test "x$ERLANG_TOKE_MESSAGE" != x],
              [AS_IF([test "x$ENABLE_TOKE" != xyes],
                [ERLANG_TOKE_MESSAGE="$ERLANG_TOKE_MESSAGE, disabling toke support..."
                 AC_MSG_NOTICE($ERLANG_TOKE_MESSAGE)],
                AC_MSG_FAILURE($ERLANG_TOKE_MESSAGE))])
            ])
AC_SUBST([ERLANG_TOKE_FLAGS])

AC_ERLANG_CHECK_LIB(common_test, , AC_MSG_NOTICE([you won't be able to run the unit tests without common_test]))

AC_CHECK_FILE($ERLANG_LIB_DIR_common_test/priv/bin/run_test,
              [AC_SUBST(RUN_TEST,[$ERLANG_LIB_DIR_common_test/priv/bin/run_test])],
              [AC_CHECK_FILE($ac_cv_erlang_root_dir/bin/run_test,
              [AC_SUBST(RUN_TEST,[$ac_cv_erlang_root_dir/bin/run_test])],
              [AC_PATH_PROG([RUN_TEST],[run_test])
               if test -z $ac_cv_path_RUN_TEST ; then
                  AC_MSG_NOTICE([run_test not found - on erlang < R14 consider running install.sh in the common_test directory otherwise you won't be able to run the unit tests])
               fi])])

AC_RUN_IFELSE(
       [AC_LANG_PROGRAM([-type(mytype()::gb_tree()).], [ok])],
       [GBTREESISBUILTIN=""; GBTREESISBUILTIN_DIALYZER=""; AC_MSG_NOTICE([gb_tree() is a built-in type])],
       [GBTREESISBUILTIN=", {d, types_not_builtin}"; GBTREESISBUILTIN_DIALYZER="-Dtypes_not_builtin"; AC_MSG_NOTICE([gb_tree() is not built-in])])

AC_RUN_IFELSE(
       [AC_LANG_PROGRAM([-type(mytype()::term()).], [ok])],
       [TERMISBUILTIN=""; TERMISBUILTIN_DIALYZER=""; AC_MSG_NOTICE([term() is a built-in type])],
       [TERMISBUILTIN=", {d, term_not_builtin}"; TERMISBUILTIN_DIALYZER="-Dterm_not_builtin"; AC_MSG_NOTICE([term() is not built-in])])

AC_RUN_IFELSE(
       [AC_LANG_PROGRAM([-type(mytype()::node()).], [ok])],
       [NODEISBUILTIN=""; NODEISBUILTIN_DIALYZER=""; AC_MSG_NOTICE([node() is a built-in type])],
       [NODEISBUILTIN=", {d, node_not_builtin}"; NODEISBUILTIN_DIALYZER="-Dnode_not_builtin"; AC_MSG_NOTICE([node() is not built-in])])

AC_RUN_IFELSE(
       [AC_LANG_PROGRAM([-type(mytype()::module()).], [ok])],
       [MODULEISBUILTIN=""; MODULEISBUILTIN_DIALYZER=""; AC_MSG_NOTICE([module() is a built-in type])],
       [MODULEISBUILTIN=", {d, module_not_builtin}"; MODULEISBUILTIN_DIALYZER="-Dmodule_not_builtin"; AC_MSG_NOTICE([module() is not built-in])])

AC_RUN_IFELSE(
       [AC_LANG_PROGRAM([-type(mytype()::boolean()).], [ok])],
       [BOOLEANISBUILTIN=""; BOOLEANISBUILTIN_DIALYZER=""; AC_MSG_NOTICE([boolean() is a built-in type])],
       [BOOLEANISBUILTIN=", {d, boolean_not_builtin}"; BOOLEANISBUILTIN_DIALYZER="-Dboolean_not_builtin"; AC_MSG_NOTICE([boolean() is not built-in])])

AC_RUN_IFELSE(
       [AC_LANG_PROGRAM([-type(mytype()::tid()).], [ok])],
       [TIDISBUILTIN=""; TIDISBUILTIN_DIALYZER=""; AC_MSG_NOTICE([tid() is a built-in type])],
       [TIDISBUILTIN=", {d, tid_not_builtin}"; TIDISBUILTIN_DIALYZER="-Dtid_not_builtin"; AC_MSG_NOTICE([tid() is not built-in])])

AC_RUN_IFELSE(
       [AC_LANG_PROGRAM([-type(mytype()::{ok, mytype()} | ok).], [ok])],
       [RECURSIVETYPESALLOWED=""; RECURSIVETYPESALLOWED_DIALYZER=""; AC_MSG_NOTICE([recursive types are supported])],
       [RECURSIVETYPESALLOWED=", {d, recursive_types_are_not_allowed}"; RECURSIVETYPESALLOWED_DIALYZER="-Drecursive_types_are_not_allowed"; AC_MSG_NOTICE([recursive types are not supported])])

AC_RUN_IFELSE(
       [AC_LANG_PROGRAM([-type(mytype()::{ok, mytype2()} | ok). -type(mytype2() :: ok).], [ok])],
       [TYPEFORWARDDECLARATIONS=""; TYPEFORWARDDECLARATIONS_DIALYZER=""; AC_MSG_NOTICE([type forward declarations are supported])],
       [TYPEFORWARDDECLARATIONS=", {d, type_forward_declarations_are_not_allowed}"; TYPEFORWARDDECLARATIONS_DIALYZER="-Dtype_forward_declarations_are_not_allowed"; AC_MSG_NOTICE([type forward declarations are not supported])])

AC_RUN_IFELSE(
       [AC_LANG_PROGRAM([[-export_type([mytype/0]). -type(mytype()::ok).]], [ok])],
       [EXPORTTYPESUPPORT=", {d, with_export_type_support}"; EXPORTTYPESUPPORT_DIALYZER="-Dwith_export_type_support"; DIALYZER_FLAGS="$DIALYZER_FLAGS -Dwith_export_type_support"; AC_MSG_NOTICE([export_type is supported])],
       [EXPORTTYPESUPPORT=""; EXPORTTYPESUPPORT_DIALYZER=""; AC_MSG_NOTICE([export_type is not supported])])

if test "x$RECURSIVETYPESALLOWED" != x -o "x$TYPEFORWARDDECLARATIONS" != x; then
   AC_MSG_NOTICE([forward declarations or recursive types are not allowed])
   FORWARDORRECURSIVE=", {d, forward_or_recursive_types_are_not_allowed}"
   FORWARDORRECURSIVE_DIALYZER="-Dforward_or_recursive_types_are_not_allowed"
fi

AC_RUN_IFELSE(
       [AC_LANG_PROGRAM([], [crypto:start()])],
       [AC_MSG_NOTICE([crypto:start() is available])],
       [AC_MSG_FAILURE([cannot start the crypto subsystem])])

EMAKEFILEDEFINES="$HAVETOKE $GBTREESISBUILTIN $TERMISBUILTIN $NODEISBUILTIN $MODULEISBUILTIN $BOOLEANISBUILTIN $TIDISBUILTIN $RECURSIVETYPESALLOWED $TYPEFORWARDDECLARATIONS $FORWARDORRECURSIVE $EXPORTTYPESUPPORT"
DIALYZER_FLAGS="$HAVETOKE_DIALYZER $GBTREESISBUILTIN_DIALYZER $TERMISBUILTIN_DIALYZER $NODEISBUILTIN_DIALYZER $MODULEISBUILTIN_DIALYZER $BOOLEANISBUILTIN_DIALYZER $TIDISBUILTIN_DIALYZER $RECURSIVETYPESALLOWED_DIALYZER $TYPEFORWARDDECLARATIONS_DIALYZER $FORWARDORRECURSIVE_DIALYZER $EXPORTTYPESUPPORT_DIALYZER"

AC_SUBST(EMAKEFILEDEFINES)
AC_SUBST(DIALYZER_FLAGS)
###########################################################
#
# check MACOSX vs. Linux for flexbisonparse driver
#
###########################################################
case `uname -s` in
 linux*)
     DRIVER_OS=LINUX
     ;;
 Linux*)
     DRIVER_OS=LINUX
     ;;
 Darwin*)
     DRIVER_OS=MACOSX
     ;;
 darwin*)
     DRIVER_OS=MACOSX
     ;;
esac

echo "detected OS is: '$DRIVER_OS'"
AC_SUBST(DRIVER_OS)

mkdir -p ~/.yaws 2> /dev/null

AC_CONFIG_FILES([Emakefile Makefile bin/scalarisctl])
AC_OUTPUT

chmod u+x bin/scalarisctl

