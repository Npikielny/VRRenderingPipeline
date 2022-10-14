import cv2
import numpy as np

img = cv2.imread('arts_quad.png')
# img = cv2.imread('grid.png')

print("Height: " + str(img.shape[0]))
print("Width: " + str(img.shape[1]))

print(min(img.shape[0], img.shape[1]))

crop_dimension = min(img.shape[0], img.shape[1])

low = int(crop_dimension/2-crop_dimension/5)
high = int(crop_dimension/2+crop_dimension/5)

print(low)
print(high)

cropped_image = img[low:high, low:high]

# K = np.array([[1,0,1],
#               [0,1,1],
#               [0,0,1]])

K = np.array([[crop_dimension/2  ,  0.  ,  1.],
              [0.  ,  crop_dimension/2  ,  1.],
              [0.  ,  0.  ,  1.]], dtype=np.float32)

# K = np.array([[  689.21,     0.  ,  1295.56],
#               [    0.  ,   690.48,   942.17],
#               [    0.  ,     0.  ,     1.  ]])

D = np.array([0., 0., 0., 0.], dtype=np.float32)

Knew = K.copy()
# Knew[(0,1), (0,1)] = 0.4 * Knew[(0,1), (0,1)]
# print(Knew[(0,1), (0,1)])

# cv2.imshow('image', cropped_image)
# cv2.imshow('image', cv2.fisheye.distortPoints(cropped_image, K, D))
cv2.imshow('image', cv2.fisheye.undistortImage(cropped_image, K, D, Knew=Knew))
# print(type(cropped_image))


cv2.waitKey(0)
