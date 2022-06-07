// Package nursery collects all functionality
// related to spawning, running, killing
// of child processes
package nursery

import (
	"sync"
)

// Nursery struct, main access
// point for this lib
type Nursery struct {
	brothers sync.WaitGroup
}

// Open creates a new Nursery and
// returns a pointer to it
func Open() *Nursery {

	return &Nursery{}
}

// Close waits for all child to finish
// returns nil, in future development
// will return a list of errors that
// children may return
func (n *Nursery) Close() error {
	n.brothers.Wait()
	return nil // TODO
}

// StartSoon starts child func asyncronously,
// passing params as parameters. It's the
// developer responsibility to cast the params
// to the proper type
func (n *Nursery) StartSoon(
	child func(params interface{}) interface{},
	params interface{}) {

	n.brothers.Add(1)
	go n.runChild(child, params)
}

func (n *Nursery) runChild(
	child func(params interface{}) interface{},
	params interface{}) {

	child(params)
	n.brothers.Done()
}
