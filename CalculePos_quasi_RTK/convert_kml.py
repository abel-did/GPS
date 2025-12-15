"""Convert CSV file to KML
"""
import csv
from os import name
from xml.dom import minidom


def node(root: minidom.Document, name: str, text: str):
    """Create node with text"""
    n = root.createElement(name)
    n_txt = root.createTextNode(text)
    n.appendChild(n_txt)
    return n


def gen_xml_doc(phase: bool = False):
    """Gen document"""
    phase_icon = "http://maps.google.com/mapfiles/kml/shapes/placemark_circle_highlight.png"
    code_icon = "http://maps.google.com/mapfiles/kml/shapes/placemark_circle.png"
    icon_ref = code_icon if not phase else phase_icon
    # Headers
    root = minidom.Document()
    xml = root.createElement("kml")
    xml.setAttribute("xmlns", "http://earth.google.com/kml/2.1")
    root.appendChild(xml)
    doc = root.createElement("Document")
    xml.appendChild(doc)
    desc = root.createElement("description")
    desc_txt = root.createTextNode("Python script to convert CSV to KML - Racoon")
    desc.appendChild(desc_txt)
    doc.appendChild(desc)

    # File name
    doc.appendChild(node(root, "name", "GPS Points"))
    doc.appendChild(node(root, "open", "1"))
    folder = root.createElement("Folder")
    doc.appendChild(folder)
    folder.appendChild(node(root, "name", "Points"))

    # Style node type 1
    style = root.createElement("Style")
    style.setAttribute("id", "s_ylw-pushpin_copy1")
    folder.appendChild(style)
    icon_style = root.createElement("IconStyle")
    style.appendChild(icon_style)
    icon_style.appendChild(node(root, "color", "FFffffff"))
    icon_style.appendChild(node(root, "scale", "1"))
    icon = root.createElement("Icon")
    icon_style.appendChild(icon)
    icon.appendChild(node(root, "href", icon_ref))
    label_style = root.createElement("LabelStyle")
    style.appendChild(label_style)
    label_style.appendChild(node(root, "color", "FFffffff"))

    # Style node type hl
    style2 = root.createElement("Style")
    style2.setAttribute("id", "s_ylw-pushpin_hl_copy1")
    folder.appendChild(style2)
    icon_style2 = root.createElement("IconStyle")
    style2.appendChild(icon_style2)
    icon_style2.appendChild(node(root, "color", "FFffffff"))
    icon_style2.appendChild(node(root, "scale", "1.2"))
    icon2 = root.createElement("Icon")
    icon_style2.appendChild(icon2)
    icon2.appendChild(node(root, "href", icon_ref))
    label_style2 = root.createElement("LabelStyle")
    style2.appendChild(label_style2)
    label_style2.appendChild(node(root, "color", "FFffffff"))

    # Style map
    style_map = root.createElement("StyleMap")
    style_map.setAttribute("id", "m_ylw-pushpin_copy2")
    folder.appendChild(style_map)
    pair = root.createElement("Pair")
    style_map.appendChild(pair)
    pair.appendChild(node(root, "key", "normal"))
    pair.appendChild(node(root, "styleUrl", "#s_ylw-pushpin_copy1"))
    pair2 = root.createElement("Pair")
    style_map.appendChild(pair2)
    pair2.appendChild(node(root, "key", "highlight"))
    pair2.appendChild(node(root, "styleUrl", "#s_ylw-pushpin_hl_copy1"))

    return root, folder


def gen_xml(file: str, out: str, phase: bool):
    """Placemark node"""
    root, folder = gen_xml_doc(phase=phase)
    name_desc = "code" if not phase else "phase"
    with open(file, newline='', encoding="utf-8") as csvfile:
        spamreader = csv.reader(csvfile, delimiter=',', quotechar='|')
        for i, co in enumerate(spamreader):
            lat, long = co
            pm = root.createElement("Placemark")
            folder.appendChild(pm)
            pm.appendChild(node(root, "name", f"{i}"))
            pm.appendChild(node(root, "description",
                                f"type: {name_desc}; point:{i}; lattitude:{lat}; longitude:{long}"))
            pm.appendChild(node(root, "styleUrl", "#m_ylw-pushpin_copy2"))
            pm.appendChild(node(root, "open", "1"))
            point = root.createElement("Point")
            pm.appendChild(point)
            point.appendChild(node(root, "coordinates", f"{long},{lat}"))

    xml_str = root.toprettyxml()
    with open(out, "w", encoding="utf-8") as f:
        f.write(xml_str)


if __name__ == "__main__":
    gen_xml("PosWGS84_phase.csv", "gps_phase.kml", phase=True)
    gen_xml("PosWGS84_code.csv", "gps_code.kml", phase=False)
