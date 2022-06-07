package trigo

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

type testParams struct {
	num1   int
	num2   int
	result chan int
}

// TestStartSoon calls a function and makes sure it executes
func TestRun(t *testing.T) {
	testChannel := make(chan int)
	params := testParams{
		num1:   2,
		num2:   40,
		result: testChannel,
	}
	Run(testFunctionParameters, params)
	assert.Equal(t, <-testChannel, 42, "result should be 1")
}

func testFunctionParameters(params interface{}) interface{} {
	param_struct := params.(testParams)
	result := param_struct.num1 + param_struct.num2
	param_struct.result <- result
	return result
}
