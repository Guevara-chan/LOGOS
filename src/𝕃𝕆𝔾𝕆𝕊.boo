# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=- #
# 𝕃𝕆𝔾𝕆𝕊 text-2-ASCIIart renderer v0.02 #
# Developed in 2020 by Victoria Guevara #
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=- #

import System
import System.Drawing
import System.Windows as SW
import System.Windows.Forms
import System.Runtime.CompilerServices
import System.Windows.Markup from 'PresentationFramework.dll'
import System.Windows.Media from 'PresentationCore.dll' as SWM

#.{ [Classes]
class ASCII_logo():
	public shape_font							= Font("Sylfaen", 20)
	public fill_font							= Font("Consolas", 7, FontStyle.Bold)
	public text_color							= Color.Pink
	public bg_color								= Color.Black
	public noise_color							= Color.FromArgb(25, 25, 25)
	public text_pool							= "01"
	public noise_pool							= "0"
	public slogan								= "I am error"
	private static final edge_factor			= 2

	# --Methods goes here.
	def done():
		return slogan.render_text(shape_font).scan_ascii(Tuple.Create(text_pool, noise_pool))\
			.render_ascii(Tuple.Create(text_color, bg_color, noise_color), fill_font)

	[Extension] static def render_text(text as string, font as Font):
		# Service objects preparation.
		sf		= StringFormat(Alignment: StringAlignment.Center, LineAlignment: StringAlignment.Center)
		# Text rendering.
		sizing	= Graphics.FromImage(Bitmap(1, 1)).MeasureString(text, font, Point(), sf)
		img		= Bitmap(sizing.Width, sizing.Height)
		render	= Graphics.FromImage(img)
		render.DrawString(text, font, SolidBrush(Color.Black), PointF(sizing.Width / 2, sizing.Height / 2), sf)
		# Finalization.
		return img

	[Extension] static def scan_ascii(ref_img as Bitmap, char_pools as Tuple[of string, string]):
		# Service objects preparation.		
		ascii		= Text.StringBuilder(); noise = Text.StringBuilder()
		ascii_gen	= EndlessString(char_pools.Item1)
		noise_gen	= EndlessString(char_pools.Item2) if char_pools.Item2
		# Reference image to ASCII conversion.
		for y in range(ref_img.Height):
			for x in range(ref_img.Width):
				pixel_found = ref_img.GetPixel(x, y).A	# Opaque -> found.
				ascii.Append((ascii_gen.next() if		pixel_found else " "))
				noise.Append((noise_gen.next() if not	pixel_found else " ")) unless noise_gen is null
			noise.AppendLine() unless noise_gen is null
			ascii.AppendLine()
		# Finalization.
		return Tuple.Create(ascii.ToString(), noise.ToString())

	[Extension]
	static def render_ascii(ascii as Tuple[of string,string], palette as Tuple[of Color,Color,Color], font as Font):
		# Service objects preparation.
		sf		= StringFormat(StringFormatFlags.MeasureTrailingSpaces, Alignment: StringAlignment.Center)
		# Image and render setup.
		sizing	= Graphics.FromImage(Bitmap(1, 1)).MeasureString(ascii.Item1, font, PointF(), sf)
		img		= Bitmap(sizing.Width, sizing.Height)
		loc		= PointF(sizing.Width / 2, 0)
		render	= Graphics.FromImage(img)
		# Primary render.
		render.Clear(palette.Item2)
		render.DrawString(ascii.Item1, font, SolidBrush(palette.Item1), loc, sf)
		# Additional bg noise render.
		if ascii.Item2:	render.DrawString(ascii.Item2, font, SolidBrush(palette.Item3), loc, sf)
		# Finalization.
		return img.Clone(Rectangle(0, 0, img.vert_edge(palette.Item2)+edge_factor, img.Height), img.PixelFormat)

	[Extension] static def vert_edge(img as Bitmap, bg_color as Color):
		# Service objects preparation.
		max_edge	= 0
		img_width	= img.Width
		img_data	= img.LockBits(Rectangle(0,0,img.Width,img.Height),1,img.PixelFormat)
		row_len		= img_data.Stride >> 2
		pixels		= array(Int32, data_len = img_data.Height * row_len)
		mark        = bg_color.ToArgb()
		# Pixel data marshaling.
		Runtime.InteropServices.Marshal.Copy(img_data.Scan0, pixels, 0, data_len)
		# Actial edge detection.
		for y in range(0, img.Height):
			edge = 0
			for x in range(0, img_width):
				edge = x if pixels[y * row_len + x] != mark
			max_edge = edge if edge > max_edge
		img.UnlockBits(img_data)
		# Finalization.
		print max_edge
		return max_edge

	# --Auxilary service subclass.
	class EndlessString():
		val as string; idx = 0
		def constructor(text as string):
			val = text
		def next():
			return val[idx = (idx+1) % val.Length]
# -------------------- #
class UI():
	def constructor():
		# Aux functions.
		def find_button(id as string) as SW.Controls.Button:
			return find_child(id)
		def color2brush(src as Color):
			return SWM.SolidColorBrush(SWM.Color.FromArgb(src.A, src.R, src.G, src.B))
		def brush2color(brush as SWM.SolidColorBrush):
			return Color.FromArgb((src = brush.Color).A, src.R, src.G, src.B)
		# Main code.
		fxcontrol = find_child('btnNoiseClr')
		find_button("btnRender").Click += {e|
			ASCII_logo(
				slogan:		find_child('iSlogan').Text,
				text_pool:	find_child('iASCII').Text,
				noise_pool:	find_child('iNoise').Text,
				bg_color:	brush2color(fxcontrol.Background),
				text_color:	brush2color(fxcontrol.BorderBrush),
				noise_color:ColorTranslator.FromHtml(fxcontrol.Content),
				shape_font:	str2font(find_child('btnShapeFnt').Content),
				fill_font:	str2font(find_child('btnFillFnt').Content)
			).done().Save(find_child('iPath').Text as String)}
		find_button('btnShapeFnt').Click	+= {e|
			fxcontrol.Background = color2brush(askfont('btnShapeFnt', brush2color(fxcontrol.Background), false))}
		find_button('btnFillFnt').Click		+= {e|
			fxcontrol.BorderBrush = color2brush(askfont('btnFillFnt', brush2color(fxcontrol.BorderBrush), true))}
		find_button('btnNoiseClr').Click	+= {e|askcolor('btnNoiseClr')}
		form.ShowDialog()

	def find_child(id as string) as duck:
		return form.FindName(id)

	def askfont(id as string, def_color as Color, mono as bool):
		dlg = FontDialog(ShowColor: true, Color: def_color, Font: str2font(find_child(id).Content), FixedPitchOnly:mono)
		if dlg.ShowDialog() != DialogResult.Cancel: find_child(id).Content = dlg.Font.font2str()
		return dlg.Color

	def askcolor(id as string):
		dlg = ColorDialog(Color: ColorTranslator.FromHtml(find_child(id).Content))
		if dlg.ShowDialog() != DialogResult.Cancel:
			btn = find_child(id)
			btn.Content = hex = ColorTranslator.ToHtml(dlg.Color)
			btn.Foreground = SWM.SolidColorBrush(SWM.ColorConverter.ConvertFromString(hex))

	[Extension] static def font2str(fnt as Font):
		idx = 1
		return "$(fnt.FontFamily.Name): $(Math.Truncate(fnt.Size))" + join(
			(('', 'b', 'i', 'u')[idx++ * Convert.ToInt32(mod)] for mod in (fnt.Bold, fnt.Italic, fnt.Underline)), '')

	[Extension] static def str2font(fcode as String):
		family, size = fcode.Split(char(':'))
		style as FontStyle; idx = 1
		for mod in ('b', 'i', 'u'):
			if size.Contains(mod):
				style += idx
				size = size.Replace(mod, '')
			idx *= 2
		return Font(family, Int32.Parse(size), style)

	# --XAML goes here:
	static final form as SW.Window = XamlReader.Parse("""
			<Window 
				xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
				xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
				Title="=[𝕃𝕆𝔾𝕆𝕊 v0.01]=" Height="150" Width="400" WindowStartupLocation="CenterScreen"
				Background="#1E1E1E">
				<Window.Resources>
					<Style TargetType="Button">
						<Setter Property="Foreground"			Value="AntiqueWhite" />
						<Setter Property="Background" Value="Transparent" />
						<Setter Property="Template">
							<Setter.Value>
								<ControlTemplate TargetType="Button">
									<Border Name="border" Background="{TemplateBinding Background}"
										BorderThickness="{TemplateBinding BorderThickness}"
											BorderBrush="{TemplateBinding BorderBrush}">
										<ContentPresenter Content="{TemplateBinding Content}"
											HorizontalAlignment="Center" VerticalAlignment="Center"/>
									</Border>
								</ControlTemplate>
							</Setter.Value>
						</Setter>
						<Style.Triggers>
							<Trigger Property="IsMouseOver"	Value="True">
								<Trigger.EnterActions>
									<BeginStoryboard>
										<Storyboard>
											<ColorAnimation Storyboard.TargetProperty="Background.Color"
												Duration="0:0:0.2" To="DarkCyan" />
											<ColorAnimation Storyboard.TargetProperty="BorderBrush.Color"
												Duration="0:0:0.2" To="DarkTurquoise" />
										</Storyboard>
									</BeginStoryboard>
								</Trigger.EnterActions>
								<Trigger.ExitActions>
									<BeginStoryboard>
										<Storyboard>
											<ColorAnimation	Storyboard.TargetProperty="Background.Color"
												Duration="0:0:0.2" />
											<ColorAnimation	Storyboard.TargetProperty="BorderBrush.Color"
												Duration="0:0:0.2" />
										</Storyboard>
									</BeginStoryboard>
								</Trigger.ExitActions>
							</Trigger>
						</Style.Triggers>
					</Style>
					<Style TargetType="TextBox">
						<Setter Property="Foreground" Value="Gold" />
						<Setter Property="Background" Value="Black" />
					</Style>
				</Window.Resources>
				<Grid>
					<Grid.RowDefinitions>
						<RowDefinition />
						<RowDefinition Height="27"/>
						<RowDefinition Height="27"/>
						<RowDefinition Height="27"/>
					</Grid.RowDefinitions>
					<Grid.ColumnDefinitions>
						<ColumnDefinition Width="48"/>
						<ColumnDefinition Width="*"	/>
						<ColumnDefinition Width="170"/>
					</Grid.ColumnDefinitions>	
					<Label HorizontalAlignment="Right" VerticalAlignment="Top" Content="Slogan:" Foreground="Coral"/>
						<TextBox	VerticalAlignment="Stretch" Grid.Row="0" Grid.Column="1" Name="iSlogan"
							Margin="0,3,5,6" Text="I am error" AcceptsReturn="True" TextWrapping="Wrap" />
						<Button		VerticalAlignment="Top" Grid.Row="0" Grid.Column="2" Name="btnShapeFnt" 
							Margin="0,3,5,3" Height="21" Content="Sylfaen: 20" />
					<Label HorizontalAlignment="Right" Content="ASCII:" Grid.Row="1" Foreground="Coral"/>
						<TextBox	Grid.Row="1" Grid.Column="1" Name="iASCII"		Margin="0,3,5,3" 
							Text="▓▒░▒" />
						<Button		Grid.Row="1" Grid.Column="2" Name="btnFillFnt"	Margin="0,3,5,3" Height="21"
							Content="Consolas: 7" />
					<Label HorizontalAlignment="Right" Content="Noise:" Grid.Row="2" Foreground="Coral"/>
						<TextBox	Grid.Row="2" Grid.Column="1" Name="iNoise"		Margin="0,3,5,3" 
							Text="1101000101001100100100" />
						<Button		Grid.Row="2" Grid.Column="2" Name="btnNoiseClr"	Margin="0,3,5,3" Height="21" 
							Content="#191919" FontFamily="Sylfaen Bold" FontSize="14" Background="Black"
							BorderBrush="Cyan" Foreground="#191919" BorderThickness="2">
							<Button.Style>
								<Style TargetType="{x:Type Button}">
									<Setter Property="Template">
										<Setter.Value>
											<ControlTemplate TargetType="Button">
												<Border Name="border" Background="{TemplateBinding Background}"
													BorderThickness="{TemplateBinding BorderThickness}"
														BorderBrush="{TemplateBinding BorderBrush}">
													<ContentPresenter Content="{TemplateBinding Content}"
														HorizontalAlignment="Center" VerticalAlignment="Center"/>
												</Border>
											</ControlTemplate>
										</Setter.Value>
									</Setter>
									<Style.Triggers>
										<Trigger Property="IsMouseOver"	Value="True">
											<Trigger.EnterActions>
												<BeginStoryboard>
													<Storyboard>
														<ColorAnimation Storyboard.TargetProperty="Foreground.Color"
															Duration="0:0:0.2" To="AntiqueWhite" />
														<ColorAnimation Storyboard.TargetProperty="Background.Color"
															Duration="0:0:0.2" To="DarkCyan" />
														<ColorAnimation Storyboard.TargetProperty="BorderBrush.Color"
															Duration="0:0:0.2" To="DarkTurquoise" />
														<ThicknessAnimation Storyboard.TargetProperty="BorderThickness"
															Duration="0:0:0.2" To="1" />
													</Storyboard>
												</BeginStoryboard>
											</Trigger.EnterActions>
											<Trigger.ExitActions>
												<BeginStoryboard>
													<Storyboard>
														<ColorAnimation	Storyboard.TargetProperty="Foreground.Color"
															Duration="0:0:0.2" />
														<ColorAnimation Storyboard.TargetProperty="Background.Color"
															Duration="0:0:0.2" />
														<ColorAnimation	Storyboard.TargetProperty="BorderBrush.Color"
															Duration="0:0:0.2" />
														<ThicknessAnimation Storyboard.TargetProperty="BorderThickness"
															Duration="0:0:0.2" />
													</Storyboard>
												</BeginStoryboard>
											</Trigger.ExitActions>
										</Trigger>
									</Style.Triggers>
							 	</Style>
							</Button.Style>
						</Button>
					<Label HorizontalAlignment="Right" Content="Out:" Grid.Row="3" Foreground="Coral"/>
						<TextBox	Grid.Row="3" Grid.Column="1" Name="iPath" Margin="0,3,5,3" Text="Output.png" />
						<Button		 VerticalAlignment="Bottom" Grid.Row="3" Grid.Column="2" Name="btnRender"
						  	Margin="0,0,5,3" Content="Render !" Height = "21" />
				</Grid>
			</Window>
		""")
#.}

# ==Main code==
[STAThread] def Main():
	UI()