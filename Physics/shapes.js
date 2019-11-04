"use strict";

class Shape {
	
	constructor(type, fillColor, borderColor, borderWidth) {

		this.type = type || false;
		this.fillColor = fillColor || "purple";
		this.borderColor = borderColor || "purple";
		this.borderWidth = borderWidth || 0;
	}

};

class Circle extends Shape {

	constructor(radius, fillColor, borderColor, borderWidth) {
		super("CIRCLE", fillColor, borderColor, borderWidth);
		this.radius = radius || 0;

		return Object.seal(this);
	}

};

class Square extends Shape {

	constructor(size, fillColor, borderColor, borderWidth) {
		super("SQUARE", fillColor, borderColor, borderWidth);
		this.width = size || 0;
		this.height = size || 0;

		return Object.seal(this);
	}

};

class Rectangle extends Shape {

	constructor(width, height, fillColor, borderColor, borderWidth) {
		super("RECTANGLE", fillColor, borderColor, borderWidth);
		this.width = width || 0;
		this.height = height || 0;

		return Object.seal(this);
	}

};