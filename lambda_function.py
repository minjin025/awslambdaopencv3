import cv2


def lambda_handler(event, context):
    print("OpenCV :", cv2.__version__)
    return "ok!"


if __name__ == "__main__":
    lambda_handler(0, 0)
