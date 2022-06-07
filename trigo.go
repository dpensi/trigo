// Package trigo aims to provide similiar
// functionalities of trio python package
// but in go
package trigo

// Run starts child func asyncronously,
// passing params as parameters. It's the
// developer responsibility to cast the params
// to the proper type
func Run(
	child func(params interface{}) interface{},
	params interface{}) {

	go child(params)
}
