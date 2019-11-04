"use strict";

class System {

	static getAcceleration(entity, target) {
		let direction = Vector.sub(target, entity.location); // Calculate a vector that points from the object to the target location
		direction.normalize(); // Normalize that vector (reducing its length to 1 "unit")
		direction.mult(0.5 * entity.mass); // Scale that vector to an appropriate value (by multiplying it by some value)

		return direction;
	}

	static update(entities, target) {
		entities.forEach(entity => {

			// If we have a target, calculate acceleration, otherwise use the existing acceleration
			if (target)
				entity.acceleration = this.getAcceleration(entity, target);

			// TODO(thomas): Needs to take angle into account...
			// if (entity.collision === true) {
			// 	this.applyForce(entity, this.getFriction(entity, 1.5));
			// 	entity.collision = false;
			// }

			this.applyForce(entity, new Vector(System.wind, 0)); // Wind
			let weight = System.gravity * entity.mass;
			this.applyForce(entity, new Vector(0, weight)); // Gravity
	  		this.applyForce(entity, this.getDrag(entity, System.airFriction)); // Normal air density friction

			entity.velocity.add(entity.acceleration);
			entity.velocity.limit(entity.maxSpeed);
			// if (entity.collision === true)
			// 	entity.location.add( entity.velocity.setMag( entity.velocity.mag() * (100 - entity.mass) / 100) );
			// else
				entity.location.add(entity.velocity);

			// entity.angleVelocity += entity.angleAcceleration;
			// entity.angle += entity.angleVelocity;
			
			this.resolveCollision(entity);
			entity.acceleration.mult(0); // Clear acceleration each time, otherwise it accumulates and goes out of whack
		});

		this.render(entities);
	}

	static getFriction(entity, coefficient) {
		let friction = entity.velocity.copy();

		friction.mult(-1);
		friction.normalize();
		friction.mult(coefficient);

		return friction;
	}

	static getDrag(entity, coefficient) {
		let speed = entity.velocity.mag();
		let dragMagnitude = coefficient * speed * speed;

		let drag = entity.velocity.copy();
		drag.mult(-1);
		drag.normalize();
		drag.mult(dragMagnitude);

		return drag;
	}

	static getRebound(entity, vectorDirection) {
		return (vectorDirection * -1);
	} 

	// TODO(thomas): Maybe make this return data about which axis collided? Set the location but return X or Y? Maybe side?
	static resolveCollision(entity) {

		let leftCalculation, rightCalculation, bottomCalculation, topCalculation;

		if (["RECTANGLE","SQUARE"].includes(entity.shape.type)) {
			leftCalculation = 0;
			rightCalculation = entity.shape.width;
			bottomCalculation = entity.shape.height;
			topCalculation = 0;
		}
		else if (entity.shape.type === "CIRCLE") {
			leftCalculation = entity.shape.radius;
			rightCalculation = entity.shape.radius;
			bottomCalculation = entity.shape.radius;
			topCalculation = entity.shape.radius;
		}

		// LEFT
		if (entity.location.x - leftCalculation < 0) {
			entity.location.x = leftCalculation + 0;
			entity.velocity.x *= -1;
			entity.collision = true;
		} // RIGHT
		else if (entity.location.x + rightCalculation > canvas.width) {
			entity.location.x = canvas.width - rightCalculation;
			entity.velocity.x *= -1;
			entity.collision = true;
		}

		// BOTTOM
		if (entity.location.y + bottomCalculation > canvas.height) {
			entity.location.y = canvas.height - bottomCalculation;
			entity.velocity.y *= -1;
			entity.collision = true;
		} // TOP
		else if (entity.location.y - topCalculation < 0) {
			entity.location.y = topCalculation;
			entity.velocity.y *= -1;
			entity.collision = true;
		}
	}

	static radians(degrees) {
		return degrees * (Math.PI / 180);
	}

	static degrees(radians) {
		return radians * (180 / Math.PI);
	}

	static render(entities) {
		drawContext.clearRect(0, 0, canvas.width, canvas.height);

		entities.forEach(entity => {

			drawContext.beginPath();
			drawContext.strokeStyle  = entity.shape.borderColor;

			if (["RECTANGLE","SQUARE"].includes(entity.shape.type))
				drawContext.rect(entity.location.x, entity.location.y, entity.shape.width, entity.shape.height);

			if (entity.shape.type === "CIRCLE")
				drawContext.arc(entity.location.x, entity.location.y, entity.shape.radius, 0, 2 * Math.PI);
			
			drawContext.stroke();
		})
	}

	static applyForce(entity, force) {
		let forceAfterMass = Vector.div(force, entity.mass);
		entity.acceleration.add(forceAfterMass);
	}
}

System.gravity = 0.6;
System.airFriction = 0.002;
System.wind = 0.008;

/*

friction
wind
gravity
drag

velocity
*/