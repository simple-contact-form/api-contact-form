# Dockerfile -> file instruksi untuk membuat docker image aplikasi kita (untuk build aplikasinya)

# Stage 1: Build the application
# golang:1.26.4-alpine sebagai buildernya 
# builder itu seperti host untuk build aplikasi kita
FROM golang:1.26.4-alpine AS builder

# Set environment variables
# ini berkaitan dengan env aplikasi golang
ENV GO111MODULE=on \
    CGO_ENABLED=0 \
    GOOS=linux \
    GOARCH=amd64

# Set working directory
WORKDIR /app

# Copy the source code
COPY . .

# Download dependencies
RUN go mod download

# Build the application
RUN go build -o api-contact-form .

# Stage 2: Create the production image
# setelah build, file binary akan dijalankan di alpine (host yg lebih ringan)
FROM alpine:latest

# Install tzdata for timezone support
RUN apk add --no-cache tzdata

# Set the timezone environment variable (can be overridden by .env)
ENV TZ=Asia/Jakarta

# Configure the timezone
RUN ln -sf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Set working directory
WORKDIR /app

# Create user and group for application
# base practice jgn menggunakan root
#
# Create a group with GID 1001
RUN addgroup -g 1001 binarygroup
# Create a user with UID 1001 and assign them to the 'binarygroup' group
RUN adduser -D -u 1001 -G binarygroup userapp

# Copy the binary from the builder stage
COPY --from=builder --chown=userapp:binarygroup /app/api-contact-form .

# Switch to the userapp user
USER userapp

# Expose port 2080
EXPOSE 2080

# Command to run the application
CMD ["./api-contact-form"]
