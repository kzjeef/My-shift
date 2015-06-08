//
//  MeasureUtil.h
//  ShiftScheduler
//
//  Created by JiejingZhang on 15/6/8.
//
//

#ifndef ShiftScheduler_MeasureUtil_h
#define ShiftScheduler_MeasureUtil_h

//
//  LOOProfiling.h
//
//  Created by Marcin Swiderski on 4/12/12.
//  Copyright (c) 2012 Marcin Swiderski. All rights reserved.
//
//  This software is provided 'as-is', without any express or implied
//  warranty.  In no event will the authors be held liable for any damages
//  arising from the use of this software.
//
//  Permission is granted to anyone to use this software for any purpose,
//  including commercial applications, and to alter it and redistribute it
//  freely, subject to the following restrictions:
//
//  1. The origin of this software must not be misrepresented; you must not
//     claim that you wrote the original software. If you use this software
//     in a product, an acknowledgment in the product documentation would be
//     appreciated but is not required.
//  2. Altered source versions must be plainly marked as such, and must not be
//     misrepresented as being the original software.
//  3. This notice may not be removed or altered from any source distribution.
//
//
// USAGE: This macro is very simple to use:
//
//     LOO_MEASURE_TIME(@"foo") {
//         ... // Some code.
//         LOO_MEASURE_TIME(@"bar") {
//             ... // Some nested code.
//         }
//         ... // Maybe some more code.
//     }
//
// Just remember not to use control instructions: return, break and goto inside the block.
// (break inside a loop in the block is okay though).

#define LOO_MEASURE_TIME(__message) \
for (CFAbsoluteTime startTime##__LINE__ = CFAbsoluteTimeGetCurrent(), endTime##__LINE__ = 0.0; endTime##__LINE__ == 0.0; \
NSLog(@"'%@' took %.6fs", (__message), (endTime##__LINE__ = CFAbsoluteTimeGetCurrent()) - startTime##__LINE__))


#endif
