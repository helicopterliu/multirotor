# This script is for blade flap calculation
# 给出旋翼挥舞模型

@everywhere function bladeflap(β, dβ, ddβ, vall_s, chord, θ0, dr, k=1)
    # 当k只取1的时候，认为所有的桨叶挥舞特性都是一致的
    # Initilize the value of β

    # 挥舞迭代计数器
    inum = Int8(0)

    while true
        inum += 1

        if inum>50
            print("挥舞迭代次数过多！失败！")
            return false
        end

        for i in 2:(npsi+1) # 一周挥舞变化
            ψ = dψ*i+2*π/Nb*(k-1)
            vall_r = Array{Vector}(Nb,Nbe)
            θ  = theget(ψ, θ0, θ_lat, θ_lon)
            vall_r = vallr(vall_s, ψ, β[k,i-1], dβ[k,i-1])
            α      = aoaget(vall_r, β[k,i-1], θ)
            ddβ[k,i] = ddβ[k,i-1]
            dβ[k,i] = dβ[k,i-1]+ddβ[k,i-1]*dt
            β[k,i] = β[k,i-1]+dβ[k,i-1]*dt+ddβ[k,i-1]*dt^2
            while true
                Mβ = bladeaero(vall_r, chord, α, β[k,i], ddβ[k,i], θ, dr, rb, k)[4]
                if abs(Mβ)<10 # 判断挥舞铰处总力矩是否为零
                    break
                end
                ddβ[k,i] += -Mβ/Iβ
            end
        end

        rmsβ = abs(β[1]-β[npsi+1]) #+abs(dβ[1]-dβ[npsi+1])+abs(
                    # ddβ[1]-ddβ[npsi+1])
        if rmsβ<1e-2
            break
        end
		β[1] 	= (β[1]+β[npsi+1])/2
		dβ[1]	= (dβ[1]+dβ[npsi+1])/2
		ddβ[1]	= (ddβ[1]+ddβ[npsi+1])/2
    end

    # 求出等效的纵横向挥舞角（用于配平）
    β1c = 0.0
    β1s = 0.0
    for i in 1:npsi
        ψ = (i-1)*dψ+(k-1)*2*π/Nb
        β1c += β[k,i]*cos(ψ)
        β1s += β[k,i]*sin(ψ)
    end
    β1c = β1c*2/npsi
    β1s = β1s*2/npsi

    return true, β, dβ, ddβ, β1c, β1s
end
