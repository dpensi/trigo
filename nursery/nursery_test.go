package nursery

import (
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
)

func testFunction(number interface{}) interface{} {

	test_channel := number.(chan int)
	time.Sleep(1 * time.Second)
	test_channel <- 1
	return nil
}

func fastFunction(intPointer interface{}) interface{} {
	ptr := intPointer.(*int)
	*ptr = 1
	return ptr
}

func slowFunction(intPointer interface{}) interface{} {
	time.Sleep(10 * time.Millisecond)
	ptr := intPointer.(*int)
	*ptr = 1
	return ptr
}

// TestStartSoon calls a function from nursery
// and makes sure it executes
func TestSingleStartSoon(t *testing.T) {
	testChannel := make(chan int)
	nursery := Nursery{}
	nursery.StartSoon(testFunction, testChannel)
	result := <-testChannel
	assert.Equal(t, result, 1, "result should be 1")
}

// TestMultipleStartSoon runs two functions and
// ensures that both are finished after call to Close
func TestMultipleStartSoon(t *testing.T) {

	probe1 := new(int)
	probe2 := new(int)

	nursery := Open()
	nursery.StartSoon(fastFunction, probe1)
	nursery.StartSoon(slowFunction, probe2)
	nursery.Close()

	assert.Equal(t, 1, *probe1, "fast function not finished")
	assert.Equal(t, 1, *probe2, "slow function not finished")

}
