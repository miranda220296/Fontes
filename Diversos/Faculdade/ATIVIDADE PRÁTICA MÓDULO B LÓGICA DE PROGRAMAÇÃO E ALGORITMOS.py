# Questão A: Mensagem de boas-vindas para apresentar no console
print("Bem-vindo(a) a loja do Lucas Miranda!")

# Questão B: Inputs valorDoPedido e quantidadedeParcelas
valorDoPedido = float(input("Digite o valor do pedido: "))
quantidadeParcelas = int(input("Digite a quantidade de parcelas: "))

# Questão C: Taxas de juros
if quantidadeParcelas < 4:
    juros = 0
elif quantidadeParcelas >= 4 and quantidadeParcelas < 6:
    juros = 0.04
elif quantidadeParcelas >= 6 and quantidadeParcelas < 9:
    juros = 0.08
elif quantidadeParcelas >= 9 and quantidadeParcelas < 13:
    juros = 0.16
else:
    juros = 0.32

# Questão D: Calculo do valor da parcela e do valor total com o juros dependendo da quantidade de parcelas
valorDaParcela = (valorDoPedido * (1 + juros)) / quantidadeParcelas
valorTotalParcelado = valorDaParcela * quantidadeParcelas

# Prints para apresentar no console
print("Bem-vindo(a) a loja do Lucas Miranda!")
print(f"O valor total do pedido parcelado é de: R${valorTotalParcelado}")
print(f"O valor de cada parcela é de: {valorDaParcela}")
