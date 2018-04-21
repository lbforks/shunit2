#! /bin/sh
# vim:et:ft=sh:sts=2:sw=2
#
# shunit2 unit test for skipping functions.


# These variables will be overridden by the test helpers.
stdoutF="${TMPDIR:-/tmp}/STDOUT"
stderrF="${TMPDIR:-/tmp}/STDERR"
returnF="${TMPDIR:-/tmp}/RETURN"

# Load test helpers.
. ./shunit2_test_helpers

# TODO macro, check lineno
# Args
#   fn: string: the assert or fail function name to be tested
#   nArgs: integer: number of dummy parameter to supply
#   reportSkip: boolean
skipTest() {
  fn=$1
  nArgs=$2
  reportSkip=${3:-${SHUNIT_FALSE}}

  fn_=${fn}
  isMacro=${SHUNIT_FALSE}
  if \[ ${fn:0:1} = '$' ]; then
    isMacro=${SHUNIT_TRUE}
    fn_=`eval echo "${fn}"`
  fi
  args=`seq ${nArgs}`
  showNoOutput=${SHUNIT_TRUE}

  (
  {
    # turn off color for cleaner output and grepping the line number
    _shunit_configureColor 'none'

    SHUNIT_REPORT_SKIP=${reportSkip}
    startSkipping
    echo "${__shunit_assertsSkipped}" >"${returnF}"
    ${fn_} ${args}
    echo "$?" >>"${returnF}"
    echo "${__shunit_assertsSkipped}" >>"${returnF}"
    endSkipping
  } >"${stdoutF}" 2>"${stderrF}"
  )

  rtrn=`sed -n '2p' <"${returnF}"`
  message="${fn}; expected success, got ${rtrn}"
  assertTrue "${message}" "[ ${rtrn} -eq ${SHUNIT_TRUE} ]"
  \[ ${rtrn} -eq ${SHUNIT_TRUE} ] || showNoOutput=${SHUNIT_FALSE}

  skippedStart=`sed -n '1p' <"${returnF}"`
  skippedEnd=`sed -n '3p' <"${returnF}"`
  message="${fn}; expected skipped count ${skippedStart} increased by 1, "
  message="${message}got ${skippedEnd}"
  assertTrue "${message}" "[ `expr ${skippedStart} + 1` -eq ${skippedEnd} ]"

  nExpectSkipMsgs=`expr ${reportSkip} = ${SHUNIT_TRUE}`
  nActualSkipMsgs=`grep '^SKIPPED:' "${stdoutF}" |wc -l`
  message="${fn}; expected skipped message count to be ${nExpectSkipMsgs}, "
  message="${message}got ${nActualSkipMsgs}"
  assertTrue "${message}" "[ ${nActualSkipMsgs} = ${nExpectSkipMsgs} ]"
  \[ ${nActualSkipMsgs} = ${nExpectSkipMsgs} ] || showNoOutput=${SHUNIT_FALSE}

  # Start skipping if LINENO not available.
  \[ -z "${LINENO:-}" ] && startSkipping
  if \[ ${isMacro} -eq ${SHUNIT_TRUE} -a ${reportSkip} -eq ${SHUNIT_TRUE} ]
  then
    grep '^SKIPPED:\[[0-9]*\]' "${stdoutF}" >/dev/null
    rtrn=$?
    assertTrue "${fn}; expected lineno, but got none" "[ ${rtrn} -eq 0 ]"
    isSkipping
    \[ $? -eq ${SHUNIT_FALSE} -a ${rtrn} -ne 0 ] && showNoOutput=${SHUNIT_FALSE}
  fi
  endSkipping

  th_showOutput "${showNoOutput}" "${stdoutF}" "${stderrF}"

  unset fn nArgs args reportSkip showNoOutput skippedStart skippedEnd rtrn \
      message nExpectSkipMsgs nActualSkipMsgs
}

skipTestSet() {
  skipTest "$@" "${SHUNIT_FALSE}"
  skipTest "$@" "${SHUNIT_TRUE}"
}

testStartSkipping() {
  (
    __shunit_skip=${SHUNIT_FALSE}
    startSkipping
    exit ${__shunit_skip}
  )
  rtrn=$?

  message="expected \${__shunit_skip} to be ${SHUNIT_TRUE}, got ${rtrn}"
  assertTrue "${message}" "[ ${rtrn} -eq ${SHUNIT_TRUE} ]"
  unset rtrn message
}

testEndSkipping() {
  (
    __shunit_skip=${SHUNIT_TRUE}
    endSkipping
    exit ${__shunit_skip}
  )
  rtrn=$?

  message="expected \${__shunit_skip} to be ${SHUNIT_FALSE}, got ${rtrn}"
  assertTrue "${message}" "[ ${rtrn} -eq ${SHUNIT_FALSE} ]"
  unset rtrn message
}

testShouldSkip() {
  (
    SHUNIT_REPORT_SKIP=${SHUNIT_FALSE}
    __shunit_skip=${SHUNIT_FALSE}
    _shunit_shouldSkip
  ) >"${stdoutF}" 2>"${stderrF}"
  rtrn=$?
  message='not skipping'
  assertFalse "${message}; expected non-zero return value" "${rtrn}"
  assertFalse "${message}; expected no output to STDOUT" "[ -s '${stdoutF}' ]"
  assertFalse "${message}; expected no output to STDERR" "[ -s '${stderrF}' ]"
  \[ -s "${stdoutF}" -o -s "${stderrF}" ] && \
      _th_showOutput "${SHUNIT_FALSE}" "${stdoutF}" "${stderrF}"
  unset rtrn message

  (
    SHUNIT_REPORT_SKIP=${SHUNIT_FALSE}
    __shunit_skip=${SHUNIT_TRUE}
    _shunit_shouldSkip
  ) >"${stdoutF}" 2>"${stderrF}"
  th_assertFalseWithError 'missing argument' "$?" "${stdoutF}" "${stderrF}"

  skipTestSet _shunit_shouldSkip 1
}

testAssertSkip() {
  (
    SHUNIT_REPORT_SKIP=${SHUNIT_FALSE}
    __shunit_skip=${SHUNIT_TRUE}
    _shunit_assertSkip
  ) >"${stdoutF}" 2>"${stderrF}"
  th_assertFalseWithError 'missing argument' "$?" "${stdoutF}" "${stderrF}"

  skipTestSet _shunit_assertSkip 1
}

testAssertEquals() {
  skipTestSet 'assertEquals' 2
  skipTestSet '${_ASSERT_EQUALS_}' 2
}

testAssertNotEquals() {
  skipTestSet 'assertNotEquals' 2
  skipTestSet '${_ASSERT_NOT_EQUALS_}' 2
}

testAssertSame() {
  skipTestSet 'assertSame' 2
  skipTestSet '${_ASSERT_SAME_}' 2
}

testAssertNotSame() {
  skipTestSet 'assertNotSame' 2
  skipTestSet '${_ASSERT_NOT_SAME_}' 2
}

testAssertNull() {
  skipTestSet 'assertNull' 1
  skipTestSet '${_ASSERT_NULL_}' 1
}

testAssertNotNull() {
  skipTestSet 'assertNotNull' 1
  skipTestSet '${_ASSERT_NOT_NULL_}' 1
}

testAssertTrue() {
  skipTestSet 'assertTrue' 1
  skipTestSet '${_ASSERT_TRUE_}' 1
}

testAssertFalse() {
  skipTestSet 'assertFalse' 1
  skipTestSet '${_ASSERT_FALSE_}' 1
}

testFail() {
  skipTestSet 'fail' 0
  skipTestSet '${_FAIL_}' 0
}

testFailNotEquals() {
  skipTestSet 'failNotEquals' 2
  skipTestSet '${_FAIL_NOT_EQUALS_}' 2
}

testFailSame() {
  skipTestSet 'failSame' 2
  skipTestSet '${_FAIL_SAME_}' 2
}

testFailNotSame() {
  skipTestSet 'failNotSame' 2
  skipTestSet '${_FAIL_NOT_SAME_}' 2
}

# Load and run shunit2.
# shellcheck disable=SC2034
[ -n "${ZSH_VERSION:-}" ] && SHUNIT_PARENT=$0
. "${TH_SHUNIT}"
