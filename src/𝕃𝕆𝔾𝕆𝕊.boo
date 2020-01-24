# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=- #
# 𝕃𝕆𝔾𝕆𝕊 text-2-ASCIIart renderer v0.06 #
# Developed in 2020 by Victoria Guevara #
# -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=- #

import System
import System.Linq
import System.Drawing
import System.Windows as SW
import System.Windows.Forms
import System.Threading.Tasks
import System.Runtime.CompilerServices
import System.Windows.Markup from 'PresentationFramework.dll'
import System.Windows.Media from 'PresentationCore.dll' as SWM
import System.Drawing.Text.TextRenderingHint as TRH

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
	public shape_hint							= TRH.SystemDefault
	public fill_hint							= TRH.SystemDefault
	public precise_scan							= true

	# --Methods goes here.
	def done():
		return slogan.render_text(shape_font, fields, shape_hint)\
						.scan_ascii(Tuple.Create(text_pool, noise_pool), precise_scan)\
						.render_ascii(Tuple.Create(text_color, bg_color, noise_color), fill_font, fill_hint)

	def begin():
		return Task.Run(done)

	[Extension] static def render_text(text as string, font as Font, fields as Size, hint as TRH):
		# Service objects preparation.
		sf		= StringFormat(Alignment: StringAlignment.Center, LineAlignment: StringAlignment.Center)
		# Init text measurement.
		sizing	= Graphics.FromImage(Bitmap(1, 1)).MeasureString(text, font, Point(), sf)
		sizing.Width	+= fields.Width * 2
		sizing.Height	+= fields.Height * 2
		# Text rendering.
		img		= Bitmap(sizing.Width, sizing.Height)
		render	= Graphics.FromImage(img)
		render.TextRenderingHint = hint
		render.DrawString(text, font, SolidBrush(Color.Black), PointF(sizing.Width / 2, sizing.Height / 2), sf)
		# Finalization.
		return img.Clone(img.find_edges(Color.FromArgb(0)).widen(fields), img.PixelFormat)

	[Extension] static def scan_ascii(ref_img as Bitmap, char_pools as Tuple[string, string], precise as bool):
		# Service objects preparation.		
		ascii		= Text.StringBuilder(); noise = Text.StringBuilder()
		ascii_gen	= EndlessString(char_pools.Item1)
		noise_gen	= EndlessString(char_pools.Item2) if char_pools.Item2
		scanlines	= Collections.Generic.List[of Task[Tuple[string, string]]]()
		img_width	= ref_img.Width
		spaces		= Enumerable.Repeat(char(' '), img_width).ToArray()
		pixels as (Int32), row_len as int = ref_img.pixel_arr()
		# Reference image to ASCII conversion.
		for y in range(ref_img.Height):
			scan_fn = def():
				ascii_ln as (char) = spaces.Clone(); noise_ln as (char) = spaces.Clone()
				for x in range(img_width):
					if pixels[y * row_len + x] != 0: ascii_ln[x] = ascii_gen.next()
					elif noise_gen: noise_ln[x] = noise_gen.next()
				return Tuple.Create(String(ascii_ln), String(noise_ln))
			scanlines.Add(last_task = Task.Run(scan_fn))
			if precise: last_task.Wait()
		# Results concatenation.
		for scanline in scanlines:
			ascii.AppendLine(scanline.Result.Item1)			
			noise.AppendLine(scanline.Result.Item2) unless noise_gen is null
		# Finalization.
		return Tuple.Create(ascii.ToString(), noise.ToString())

	[Extension]
	static def render_ascii(ascii as Tuple[string,string],palette as Tuple[Color,Color,Color],font as Font,hint as TRH):
		# Service objects preparation.
		sf		= StringFormat(StringFormatFlags.MeasureTrailingSpaces, Alignment: StringAlignment.Center,
			LineAlignment: StringAlignment.Center)
		margin	= Size(1, 3)
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
		render.TextRenderingHint = hint
		render.DrawString(ascii.Item1, font, SolidBrush(palette.Item1), loc, sf)
		# Additional bg noise render.
		if ascii.Item2:	render.DrawString(ascii.Item2, font, SolidBrush(palette.Item3), loc, sf)
		# Finalization.
		return img.Clone(img.find_edges(palette.Item2).widen(margin), img.PixelFormat)

	[Extension] static def find_edges(img as Bitmap, bg_color as Color):
		# Service objects preparation.
		img_width	= img.Width
		img_height	= img.Height
		mark		= bg_color.ToArgb()
		scanlines	= Collections.Generic.List[of Task[(int)]]()
		pixels as (Int32), row_len as int	= img.pixel_arr()
		vl_edge, vr_edge, hu_edge, hb_edge	= (img_width, 0, img_height, 0)
		# Edge detection.
		for y in range(0, img_height):
			scan_fn = def():
				vl_scan = img_width
				vr_scan = 0
				for x in range(0, img_width):
					if pixels[y * row_len + x] != mark:
						vr_scan = x
						vl_scan = x unless vl_scan < img_width
				return (vl_scan, vr_scan)
			scanlines.Add(Task.Run(scan_fn))
		# Scan analyzis.
		y = 0
		for scanline in scanlines:
			vl_scan, vr_scan = scanline.Result
			if vr_scan:
				hb_edge = y if y > hb_edge
				hu_edge = y unless hu_edge < img_height
			vl_edge = vl_scan if vl_scan < vl_edge
			vr_edge = vr_scan if vr_scan > vr_edge
			y++
		# Finalization.
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
		val as string; idx = -1
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

		# Input event handlers.
		fxcontrol = find_child('btnNoiseClr')
		for id in ("iHMargin", "iVMargin"):	(find_child(id) as SW.Controls.TextBox).PreviewTextInput += num_filter
		# Combobox filling.
		for id in ("cSloganDraw", "cPatternDraw"):
			items = (cb = find_child(id) as SW.Controls.ComboBox).Items
			for name in Enum.GetNames(TRH): items.Add(name)
			cb.SelectedIndex = 0
		# Main click event handler.
		find_button("btnRender").Click += def(sender as SW.Controls.Button):
			try:
				form.IsEnabled = false
				ASCII_logo(
					fields:		Size(Int32.Parse(find_child('iHMargin').Text),Int32.Parse(find_child("iVMargin").Text)),
					slogan:		find_child('iSlogan').Text,
					text_pool:	find_child('iASCII').Text,
					noise_pool:	find_child('iNoise').Text,
					bg_color:	brush2color(fxcontrol.Background),
					text_color:	brush2color(fxcontrol.BorderBrush),
					noise_color:ColorTranslator.FromHtml(fxcontrol.Content),
					shape_font:	str2font(find_child('btnShapeFnt').Content),
					fill_font:	str2font(find_child('btnFillFnt').Content),
					shape_hint: Enum.Parse(TRH, (find_child("cSloganDraw") as SW.Controls.ComboBox).SelectedItem),
					fill_hint:	Enum.Parse(TRH, (find_child("cPatternDraw") as SW.Controls.ComboBox).SelectedItem),
					precise_scan: not find_child('cbFastRender').IsChecked
				).begin().gauge_performance(sender).Save(find_child('iPath').Text as String)
			except ex: MessageBox.Show("FAULT:: $(ex.Message)", form.Title, 0, MessageBoxIcon.Error)
			ensure: GC.Collect(); form.IsEnabled = true
		# Aux event handlers.
		find_button('btnShapeFnt').Click	+= {e|
			fxcontrol.Background = color2brush(askfont('btnShapeFnt', brush2color(fxcontrol.Background), false))}
		find_button('btnFillFnt').Click		+= {e|
			fxcontrol.BorderBrush = color2brush(askfont('btnFillFnt', brush2color(fxcontrol.BorderBrush), true))}
		find_button('btnNoiseClr').Click	+= {e|askcolor('btnNoiseClr')}
		# Finalization.
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

	[Extension] static def gauge_performance[of T](task as Task[T], counter as SW.Controls.Button):
		start	= DateTime.Now
		backup	= counter.Content
		while not task.IsCompleted:
			counter.Content = (DateTime.Now - start).ToString("mm\\:ss\\.ff")
			Application.DoEvents()
			Threading.Thread.Sleep(50)
		counter.Content = backup
		return task.Result

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
				Title="=[𝕃𝕆𝔾𝕆𝕊 v0.06]=" Height="204" Width="400" WindowStartupLocation="CenterScreen"
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
							<Trigger Property="IsEnabled" Value="False">
								<Trigger.EnterActions>
									<BeginStoryboard>
										<Storyboard>
											<DoubleAnimation Storyboard.TargetProperty="Opacity" To="0.5"
												Duration="0:0:0" />
										</Storyboard>
									</BeginStoryboard>
								</Trigger.EnterActions>
								<Trigger.ExitActions>
									<BeginStoryboard>
										<Storyboard>
											<DoubleAnimation Storyboard.TargetProperty="Opacity" Duration="0:0:0" />
										</Storyboard>
									</BeginStoryboard>
								</Trigger.ExitActions>
							</Trigger>
						</Style.Triggers>
					</Style>
					<LinearGradientBrush x:Key="NormalBrush" StartPoint="0,0" EndPoint="0,1">
						<GradientBrush.GradientStops>
							<GradientStopCollection>
								<GradientStop Color="#1E1E1E" Offset="0.0"/>
								<GradientStop Color="DimGray" Offset="1.0"/>
							</GradientStopCollection>
					 	</GradientBrush.GradientStops>
					</LinearGradientBrush>
					<ControlTemplate x:Key="ComboBoxToggleButton" TargetType="ToggleButton">
						<Grid>
							<Grid.ColumnDefinitions>
								<ColumnDefinition />
								<ColumnDefinition Width="20" />
							</Grid.ColumnDefinitions>
							<Border Name="Border" Grid.ColumnSpan="2" BorderBrush="{TemplateBinding BorderBrush}"
								Background="{StaticResource NormalBrush}" BorderThickness="1" />
							<Border Grid.Column="0" CornerRadius="2,0,0,2" Margin="1" 
								Background="#EE000000" BorderThickness="0,0,1,0" />
							<Path x:Name="Arrow" Grid.Column="1" HorizontalAlignment="Center" VerticalAlignment="Center"
								Fill="{TemplateBinding Background}" Data="M 0 0 L 4 4 L 8 0 Z"/>
						</Grid>
					</ControlTemplate>
					<ControlTemplate x:Key="ComboBoxTextBox" TargetType="TextBox">
						<Border x:Name="PART_ContentHost" Focusable="False" Background="{TemplateBinding Background}"/>
					</ControlTemplate>
					<Style x:Key="{x:Type ComboBox}" TargetType="ComboBox">
						<Setter Property="BorderBrush" Value="#FFABADB3" />
						<Setter Property="Background" Value="AntiqueWhite" />
						<Setter Property="Template">
							<Setter.Value>
						 		<ControlTemplate TargetType="ComboBox">
						  			<Grid>
										<ToggleButton Name="ToggleButton" Grid.Column="2" Focusable="false" 
											Template="{StaticResource ComboBoxToggleButton}" ClickMode="Press"
							 				IsChecked="{Binding Path=IsDropDownOpen,Mode=TwoWay,
							 					RelativeSource={RelativeSource TemplatedParent}}" 
							 				BorderBrush="{TemplateBinding BorderBrush}" 
							 				Background="{TemplateBinding Background}"/>
						  				<ContentPresenter
											Name="ContentSite" IsHitTestVisible="False" Margin="3,3,23,3"
											VerticalAlignment="Center" HorizontalAlignment="Left" 
											Content="{TemplateBinding ComboBox.SelectionBoxItem}"
											ContentTemplate="{TemplateBinding ComboBox.SelectionBoxItemTemplate}"
											ContentTemplateSelector="{TemplateBinding ItemTemplateSelector}" />
										<TextBox x:Name="PART_EditableTextBox" Style="{x:Null}" Visibility="Hidden" 
											Template="{StaticResource ComboBoxTextBox}" HorizontalAlignment="Left" 
											VerticalAlignment="Center" Margin="3,3,23,3" Focusable="True"
											Background="Transparent" IsReadOnly="{TemplateBinding IsReadOnly}"/>
						  				<Popup Name="Popup"	Placement="Bottom" IsOpen="{TemplateBinding IsDropDownOpen}"
											AllowsTransparency="True" Focusable="False"	PopupAnimation="Slide">
											<Grid Name="DropDown" SnapsToDevicePixels="True" 
												MinWidth="{TemplateBinding ActualWidth}"
												MaxHeight="{TemplateBinding MaxDropDownHeight}">
												<Border x:Name="DropDownBorder"	Background="#EE000000" 
													BorderThickness="1"/>
												<ScrollViewer Margin="4,6,4,6" SnapsToDevicePixels="True">
													<StackPanel IsItemsHost="True"
														KeyboardNavigation.DirectionalNavigation="Contained" />
												</ScrollViewer>
							  				</Grid>
							 			</Popup>
									</Grid>
								</ControlTemplate>
							</Setter.Value>
						</Setter>
						<Style.Triggers>
							<Trigger Property="IsMouseOver"	Value="True">
								<Trigger.EnterActions>
									<BeginStoryboard>
										<Storyboard>
											<ColorAnimation Storyboard.TargetProperty="BorderBrush.Color"
												Duration="0:0:0.2" To="CornflowerBlue" />
											<ColorAnimation Storyboard.TargetProperty="Background.Color"
												Duration="0:0:0.2" To="CornflowerBlue" />
										</Storyboard>
									</BeginStoryboard>
								</Trigger.EnterActions>
								<Trigger.ExitActions>
									<BeginStoryboard>
										<Storyboard>
											<ColorAnimation	Storyboard.TargetProperty="BorderBrush.Color"
												Duration="0:0:0.2" />
											<ColorAnimation	Storyboard.TargetProperty="Background.Color"
												Duration="0:0:0.2" />
										</Storyboard>
									</BeginStoryboard>
								</Trigger.ExitActions>
							</Trigger>
							<Trigger Property="IsEnabled" Value="False">
								<Trigger.EnterActions>
									<BeginStoryboard>
										<Storyboard>
											<DoubleAnimation Storyboard.TargetProperty="Opacity" To="0.5"
												Duration="0:0:0" />
										</Storyboard>
									</BeginStoryboard>
								</Trigger.EnterActions>
								<Trigger.ExitActions>
									<BeginStoryboard>
										<Storyboard>
											<DoubleAnimation Storyboard.TargetProperty="Opacity" Duration="0:0:0" />
										</Storyboard>
									</BeginStoryboard>
								</Trigger.ExitActions>
							</Trigger>
						</Style.Triggers>
					</Style>
					<Style x:Key="{x:Type CheckBox}" TargetType="{x:Type CheckBox}">
            			<Setter Property="SnapsToDevicePixels" Value="true"/>
            			<Setter Property="OverridesDefaultStyle" Value="true"/>
            			<Setter Property="Template">
                			<Setter.Value>
                    			<ControlTemplate TargetType="{x:Type CheckBox}">
                        			<BulletDecorator Background="Transparent">
                            			<BulletDecorator.Bullet>
                                			<Border x:Name="Border" Width="13" Height="13" CornerRadius="0" 
                                				Background="Black" BorderThickness="1" BorderBrush="#FFABADB3">
                                				<Path Width="7" Height="7" x:Name="CheckMark" 
                                					SnapsToDevicePixels="False" Stroke="Orange" StrokeThickness="2"
                                					Data="M 0 0 L 7 7 M 0 7 L 7 0" />
                                			</Border>
                            			</BulletDecorator.Bullet>
                            			<ContentPresenter Margin="4,0,0,0" VerticalAlignment="Center" 
                            				HorizontalAlignment="Left" RecognizesAccessKey="True"/>
                        			</BulletDecorator>
									<ControlTemplate.Triggers>
										<Trigger Property="IsChecked" Value="false">
											<Setter TargetName="CheckMark" Property="Visibility" Value="Collapsed"/>
										</Trigger>
										<Trigger Property="IsChecked" Value="{x:Null}">
											<Setter TargetName="CheckMark" Property="Data" Value="M 0 7 L 7 0" />
										</Trigger>
										<Trigger Property="IsMouseOver" Value="true">
											<Setter TargetName="Border" Property="BorderBrush" Value="CornflowerBlue" />
										</Trigger>
										<Trigger Property="IsPressed" Value="true">
											<Setter TargetName="Border" Property="Background" Value="#1E1E1E" />
										</Trigger>
										<Trigger Property="IsEnabled" Value="false">
											<Setter TargetName="Border" Property="BorderBrush" Value="DimGray" />
											<Setter Property="Foreground" Value="Gray"/>
										</Trigger>
									</ControlTemplate.Triggers>
								</ControlTemplate>
							</Setter.Value>
						</Setter>
					</Style>
					<Style TargetType="TextBox">
						<Setter Property="Foreground" Value="Gold" />
						<Setter Property="Background" Value="Black" />
					</Style>
					<Style TargetType="Label">
						<Setter Property="HorizontalAlignment" Value="Right" />
					</Style>
				</Window.Resources>
				<Grid>
					<Grid.RowDefinitions>
						<RowDefinition />
						<RowDefinition Height="27"/>
						<RowDefinition Height="27"/>
						<RowDefinition Height="54"/>
						<RowDefinition Height="27"/>
					</Grid.RowDefinitions>
					<Grid.ColumnDefinitions>
						<ColumnDefinition Width="48"/>
						<ColumnDefinition Width="*"	/>
						<ColumnDefinition Width="170"/>
					</Grid.ColumnDefinitions>	
					<Label VerticalAlignment="Top" Content="Slogan:" Foreground="Coral"/>
						<TextBox	VerticalAlignment="Stretch" Grid.Row="0" Grid.Column="1" x:Name="iSlogan"
							Margin="0,3,5,6" Text="I am error" AcceptsReturn="True" TextWrapping="Wrap" />
						<Button		VerticalAlignment="Top" Grid.Row="0" Grid.Column="2" x:Name="btnShapeFnt" 
							Margin="0,3,5,3" Height="21" Content="Sylfaen: 20" />
					<Label Content="ASCII:" Grid.Row="1" Foreground="Coral"/>
						<TextBox	Grid.Row="1" Grid.Column="1" x:Name="iASCII"		Margin="0,3,5,3" 
							Text="▓▒░▒" />
						<Button		Grid.Row="1" Grid.Column="2" x:Name="btnFillFnt"	Margin="0,3,5,3" Height="21"
							Content="Consolas: 7" />
					<Label Content="Noise:" Grid.Row="2" Foreground="Coral"/>
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
										<Trigger Property="IsEnabled" Value="False">
											<Trigger.EnterActions>
												<BeginStoryboard>
													<Storyboard>
														<DoubleAnimation Storyboard.TargetProperty="Opacity" To="0.5"
															Duration="0:0:0" />
													</Storyboard>
												</BeginStoryboard>
											</Trigger.EnterActions>
											<Trigger.ExitActions>
												<BeginStoryboard>
													<Storyboard>
														<DoubleAnimation Storyboard.TargetProperty="Opacity"
															Duration="0:0:0" />
													</Storyboard>
												</BeginStoryboard>
											</Trigger.ExitActions>
										</Trigger>
									</Style.Triggers>
							 	</Style>
							</Button.Style>
						</Button>
					<CheckBox x:Name="cbFastRender" Content="Fast:" Grid.Row="4" Foreground="Coral" Margin="0,0,2,0"
						HorizontalAlignment="Right" VerticalAlignment="Center" Background="Black" />
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
						<Grid.RowDefinitions>
							<RowDefinition Height="27"/>
							<RowDefinition Height="27"/>
						</Grid.RowDefinitions>
						<Label Content="Slogan draw:" Grid.Column="0" Foreground="LightCoral"/>
							<ComboBox x:Name="cSloganDraw" Grid.Column="1" Margin="0,3,5,3" Foreground="Coral"/>
						<Label Content="Pattern draw:" Grid.Column="2" Foreground="LightCoral"/>
							<ComboBox x:Name="cPatternDraw" Grid.Column="3" Margin="0,3,5,3" Foreground="Coral"/>
						<Label Content="Horiz margin:" Foreground="LightCoral" Grid.Column="0" Grid.Row = "1"/>
							<TextBox x:Name="iHMargin" Text="5" Grid.Column="1" Grid.Row = "1" Margin="0,3,5,3"
								Foreground="DarkOrange"/>
						<Label Content="Vert margin:" Foreground="LightCoral" Grid.Column="2" Grid.Row = "1"/>
							<TextBox x:Name="iVMargin" Text="3" Grid.Column="3" Grid.Row = "1" Margin="0,3,5,3"
								Foreground="DarkOrange"/>
					</Grid>
				</Grid>
			</Window>
		""")
#.}

# ==Main code==
[STAThread] def Main():
	UI()