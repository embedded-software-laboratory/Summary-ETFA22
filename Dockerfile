FROM alpine:3.14 AS build

RUN apk add alpine-sdk git; 						            \
    apk add openjdk8-jre; 						                \	
    apk add clang cmake make; 					                \
    apk add z3 z3-dev boost-dev boost boost-program_options; 	\
    apk add libuuid util-linux-dev gmp gmp-dev;
    
RUN mkdir -p /etfa22/contribution/bin && curl https://www.antlr.org/download/antlr-4.9.3-complete.jar --output /etfa22/contribution/bin/antlr-4.9.3-complete.jar
    
COPY ./ahorn /etfa22/contribution

WORKDIR /etfa22/contribution
RUN mkdir build && cd build; 								                    \
    cmake ../ 										                            \ 
    	-DCMAKE_BUILD_TYPE=RELEASE 							                    \
    	-DANTLR_EXECUTABLE=/etfa22/contribution/bin/antlr-4.9.3-complete.jar; 	\
    	make;

FROM alpine:3.14 AS evaluation

ENV EVALUATION /etfa22/evaluation
WORKDIR ${EVALUATION}

RUN apk add z3 boost;
COPY --from=build /etfa22/contribution/build ${EVALUATION}/bin
COPY ./benchmark /etfa22/evaluation/benchmark

COPY evaluation.sh $EVALUATION/evaluation.sh
ENTRYPOINT ["/bin/sh", "/etfa22/evaluation/evaluation.sh"]
CMD ["0"]

