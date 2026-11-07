import 'package:flutter/material.dart';
import 'package:ecommerce/core/utils/responsive_utils.dart';
import 'package:ecommerce/core/widgets/app_text_field.dart';
import 'package:ecommerce/core/widgets/app_button.dart';

class ForgotPasswordFormWidget extends StatelessWidget {
  final TextEditingController emailController;
  final bool isLoading;
  final VoidCallback onSubmitPressed;

  const ForgotPasswordFormWidget({
    super.key,
    required this.emailController,
    required this.isLoading,
    required this.onSubmitPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          controller: emailController,
          labelText: 'Email',
          hintText: 'amelia.wood@gmail.com',
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        SizedBox(height: 32.h(context)),
        AppButton(
          text: 'SEND INSTRUCTIONS',
          onPressed: onSubmitPressed,
          isLoading: isLoading,
        ),
      ],
    );
  }
}
