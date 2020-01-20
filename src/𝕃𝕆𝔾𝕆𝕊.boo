# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=- #
# 𝕃𝕆𝔾𝕆𝕊 text-2-ASCIIart renderer v0.04f #
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
	public fields								= Size(5, 3)
	public shape_font							= Font("Sylfaen", 20)
	public fill_font							= Font("Consolas", 7, FontStyle.Bold)
	public text_color							= Color.Pink
	public bg_color								= Color.Black
	public noise_color							= Color.FromArgb(25, 25, 25)
	public text_pool							= "01"
	public noise_pool							= "0"
	public slogan								= "I am error"

	# --Methods goes here.
	def done():
		return slogan.render_text(shape_font, fields).scan_ascii(Tuple.Create(text_pool, noise_pool))\
			.render_ascii(Tuple.Create(text_color, bg_color, noise_color), fill_font)

	[Extension] static def render_text(text as string, font as Font, fields as Size):
		# Service objects preparation.
		sf		= StringFormat(Alignment: StringAlignment.Center, LineAlignment: StringAlignment.Center)
		# Init text measurement.
		sizing	= Graphics.FromImage(Bitmap(1, 1)).MeasureString(text, font, Point(), sf)
		sizing.Width	+= fields.Width * 2
		sizing.Height	+= fields.Height * 2
		# Text rendering.
		img		= Bitmap(sizing.Width, sizing.Height)
		render	= Graphics.FromImage(img)
		render.DrawString(text, font, SolidBrush(Color.Black), PointF(sizing.Width / 2, sizing.Height / 2), sf)
		# Finalization.
		return img.Clone(img.find_edges(Color.FromArgb(0)).widen(fields), img.PixelFormat)

	[Extension] static def scan_ascii(ref_img as Bitmap, char_pools as Tuple[of string, string]):
		# Service objects preparation.		
		ascii		= Text.StringBuilder(); noise = Text.StringBuilder()
		ascii_gen	= EndlessString(char_pools.Item1)
		noise_gen	= EndlessString(char_pools.Item2) if char_pools.Item2
		pixels as (Int32), row_len as int = ref_img.pixel_arr()
		# Reference image to ASCII conversion.
		for y in range(ref_img.Height):
			for x in range(ref_img.Width):
				pixel_found = pixels[y * row_len + x] != 0 # Non-null -> found.
				ascii.Append((ascii_gen.next() if		pixel_found else " "))
				noise.Append((noise_gen.next() if not	pixel_found else " ")) unless noise_gen is null
			noise.AppendLine() unless noise_gen is null
			ascii.AppendLine()
		# Finalization.
		return Tuple.Create(ascii.ToString(), noise.ToString())

	[Extension]
	static def render_ascii(ascii as Tuple[of string,string], palette as Tuple[of Color,Color,Color], font as Font):
		# Service objects preparation.
		sf			= StringFormat(StringFormatFlags.MeasureTrailingSpaces, Alignment: StringAlignment.Center,
			LineAlignment: StringAlignment.Center)
		margin		= Size(1, 3)
		# Init text measurement.
		sizing	= Graphics.FromImage(Bitmap(1, 1)).MeasureString(ascii.Item1, font, PointF(), sf)		
		sizing.Width	+= margin.Width * 2
		sizing.Height	+= margin.Height * 2
		# Image and render setup.
		img		= Bitmap(sizing.Width, sizing.Height)
		loc		= PointF(sizing.Width / 2, sizing.Height / 2)
		render	= Graphics.FromImage(img)
		# Primary render.
		render.Clear(palette.Item2)
		render.DrawString(ascii.Item1, font, SolidBrush(palette.Item1), loc, sf)
		# Additional bg noise render.
		if ascii.Item2:	render.DrawString(ascii.Item2, font, SolidBrush(palette.Item3), loc, sf)
		# Finalization.
		return img.Clone(img.find_edges(palette.Item2).widen(margin), img.PixelFormat)

	[Extension] static def find_edges(img as Bitmap, bg_color as Color):
		# Service objects preparation.
		img_width	= img.Width
		img_height	= img.Height
		mark        = bg_color.ToArgb()
		pixels as (Int32), row_len as int	= img.pixel_arr()
		vl_edge, vr_edge, hu_edge, hb_edge	= (img_width, 0, img_height, 0)
		# Edge detection.
		for y in range(0, img_height):
			vl_scan = img_width
			vr_scan = 0
			for x in range(0, img_width):
				if pixels[y * row_len + x] != mark:
					vr_scan = x
					vl_scan = x unless vl_scan < img_width
			if vr_scan:
				hb_edge = y if y > hb_edge
				hu_edge = y unless hu_edge < img_height
			vl_edge = vl_scan if vl_scan < vl_edge
			vr_edge = vr_scan if vr_scan > vr_edge
		# Finalization
		return Rectangle(vl_edge, hu_edge, vr_edge-vl_edge+1, hb_edge-hu_edge+1)

	[Extension] static def pixel_arr(img as Bitmap):
		# Service objects preparation.
		img_data	= img.LockBits(Rectangle(0,0,img.Width,img.Height),1,img.PixelFormat)
		row_len		= img_data.Stride >> 2
		pixels		= array(Int32, data_len = img_data.Height * row_len)
		# Pixel data marshaling.
		Runtime.InteropServices.Marshal.Copy(img_data.Scan0, pixels, 0, data_len)
		# Finalization.
		img.UnlockBits(img_data)
		return (pixels, row_len)

	[Extension] static def widen(area as Rectangle, margin as Size):
		return Rectangle(area.X-margin.Width,area.Y-margin.Height,area.Width+margin.Width*2,area.Height+margin.Height*2)

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
		for id in ("iHMargin", "iVMargin"):	(find_child(id) as SW.Controls.TextBox).PreviewTextInput += num_filter
		find_button("btnRender").Click += {e|
			ASCII_logo(
				fields:		Size(Int32.Parse(find_child('iHMargin').Text), Int32.Parse(find_child("iVMargin").Text)),
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

	def num_filter(sender, e as Windows.Input.TextCompositionEventArgs):
		e.Handled = Text.RegularExpressions.Regex("[^0-9]").IsMatch(e.Text)		

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
				Title="=[𝕃𝕆𝔾𝕆𝕊 v0.04]=" Height="180" Width="400" WindowStartupLocation="CenterScreen"
				Background="#1E1E1E">
				<Window.Resources>
					<Style TargetType="Button">
						<Setter Property="Foreground" Value="AntiqueWhite" />
						<Setter Property="Background" Value="Transparent" />
						<Setter Property="Template">
							<Setter.Value>
								<ControlTemplate TargetType="Button">
									<Border x:Name="border" Background="{TemplateBinding Background}"
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
						<RowDefinition Height="27"/>
					</Grid.RowDefinitions>
					<Grid.ColumnDefinitions>
						<ColumnDefinition Width="48"/>
						<ColumnDefinition Width="*"	/>
						<ColumnDefinition Width="170"/>
					</Grid.ColumnDefinitions>	
					<Label HorizontalAlignment="Right" VerticalAlignment="Top" Content="Slogan:" Foreground="Coral"/>
						<TextBox	VerticalAlignment="Stretch" Grid.Row="0" Grid.Column="1" x:Name="iSlogan"
							Margin="0,3,5,6" Text="I am error" AcceptsReturn="True" TextWrapping="Wrap" />
						<Button		VerticalAlignment="Top" Grid.Row="0" Grid.Column="2" x:Name="btnShapeFnt" 
							Margin="0,3,5,3" Height="21" Content="Sylfaen: 20" />
					<Label HorizontalAlignment="Right" Content="ASCII:" Grid.Row="1" Foreground="Coral"/>
						<TextBox	Grid.Row="1" Grid.Column="1" x:Name="iASCII"		Margin="0,3,5,3" 
							Text="▓▒░▒" />
						<Button		Grid.Row="1" Grid.Column="2" x:Name="btnFillFnt"	Margin="0,3,5,3" Height="21"
							Content="Consolas: 7" />
					<Label HorizontalAlignment="Right" Content="Noise:" Grid.Row="2" Foreground="Coral"/>
						<TextBox	Grid.Row="2" Grid.Column="1" x:Name="iNoise"		Margin="0,3,5,3" 
							Text="1101000101001100100100" />
						<Button		Grid.Row="2" Grid.Column="2" x:Name="btnNoiseClr"	Margin="0,3,5,3" Height="21" 
							Content="#191919" FontFamily="Sylfaen Bold" FontSize="14" Background="Black"
							BorderBrush="Cyan" Foreground="#191919" BorderThickness="2">
							<Button.Style>
								<Style TargetType="{x:Type Button}">
									<Setter Property="Template">
										<Setter.Value>
											<ControlTemplate TargetType="Button">
												<Border x:Name="border" Background="{TemplateBinding Background}"
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
					<Label HorizontalAlignment="Right" Content="Out:" Grid.Row="4" Foreground="Coral"/>
						<TextBox	Grid.Row="4" Grid.Column="1" x:Name="iPath" Margin="0,3,5,3" Text="Output.png" />
						<Button		 VerticalAlignment="Bottom" Grid.Row="4" Grid.Column="2" x:Name="btnRender"
						  	Margin="0,0,5,3" Content="Render !" Height = "21" />
					<Grid Grid.Row="3" Grid.ColumnSpan="3">
						<Grid.ColumnDefinitions>
							<ColumnDefinition Width="81"/>
							<ColumnDefinition Width="*"/>
							<ColumnDefinition Width="81"/>
							<ColumnDefinition Width="*"/>
						</Grid.ColumnDefinitions>
						<Label Content="Horiz margin:" Foreground="LightCoral" Grid.Column="0"/>
						<TextBox x:Name="iHMargin" Text="5" Grid.Column="1" Margin="0,3,5,3" Foreground="DarkOrange"/>
						<Label Content="Vert margin:" Foreground="LightCoral" Grid.Column="2"/>
						<TextBox x:Name="iVMargin" Text="3" Grid.Column="3" Margin="0,3,5,3" Foreground="DarkOrange"/>
					</Grid>
				</Grid>
			</Window>
		""")
#.}

# ==Main code==
[STAThread] def Main():
	UI()