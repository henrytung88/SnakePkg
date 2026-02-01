#ifndef __GAMELOGIC_H__
#define __GAMELOGIC_H__

#define CELLS_PER_AXIS                      9
#define CELL_PERCENTAGE_SCREEN_OCCUPANCY    3
#define CELL_BORDER_SIZE                    2
#define SNAKE_INITIAL_LENGTH                5

#define GRID_CELL_COUNT                     (CELLS_PER_AXIS * CELLS_PER_AXIS)

#define CELL_X(Index)                       (Index % CELLS_PER_AXIS)
#define CELL_Y(Index)                       (Index / CELLS_PER_AXIS)
#define CELL_INDEX(X, Y)                    ((Y * CELLS_PER_AXIS) + X)
#define IS_SNAKE_CELL(Cell)                 (Cell == 1)
#define IS_APPLE_CELL(Cell)                 (Cell == 2)

typedef UINT16                              GRID_CELL;
typedef GRID_CELL                           GRID_MATRIX[CELLS_PER_AXIS * CELLS_PER_AXIS];

typedef enum {
  Undefined,
  RelativeUp,
  RelativeDown,
  RelativeLeft,
  RelativeRight
} DIRECTION_VECTOR;

typedef struct {
  UINT16        Length;
  GRID_MATRIX   OccupiedCells; // It's not used as a matrix, but I want to avoid boilerplate code
} SNAKE_STATE;

VOID
RunGameLogic(
  VOID
);

#endif
