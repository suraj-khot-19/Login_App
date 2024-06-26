import 'package:firebase1/Widget/support_widget/controllers.dart';
import 'package:firebase1/Widget/support_widget/sized_box.dart';
import 'package:firebase1/Widget/utils/all_management.dart';
import 'package:firebase1/Widget/utils/exit_confirm.dart';
import 'package:firebase1/Widget/utils/utils.dart';
import 'package:firebase1/screens/add_note.dart';
import 'package:firebase1/verify_screens/auth/Email/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MyHome extends StatefulWidget {
  const MyHome({
    super.key,
  });

  @override
  State<MyHome> createState() => _MyHomeState();
}

class _MyHomeState extends State<MyHome> {
  final _auth = FirebaseAuth.instance;
  final ref = FirebaseDatabase.instance.ref();
  String searchFilterString = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: InkWell(
            onTap: onClickBtn,
            child: Icon(
              Icons.menu_sharp,
            )),
        title: Row(
          children: [
            Container(
                height: 35,
                child: Image.asset(
                  'assets/images/app12.png',
                  fit: BoxFit.fitHeight,
                )),
            addHorizontalSpace(80),
            Text(
              StringManger().appName,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    color: Colors.pink.withOpacity(0.8),
                    offset: Offset(1.0, 1.0),
                    blurRadius: 3.0,
                  ),
                ],
              ),
            )
          ],
        ),
        actions: [
          Row(
            children: [
              IconButton(
                onPressed: () => _confirmLogout(),
                icon: const Icon(
                  Icons.logout,
                ),
              ),
            ],
          ),
          addHorizontalSpace(10),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.only(left: 20, right: 20, top: 10),
        child: Column(
          children: [
            const ExitConfirmationDialog(),
            addVerticalSpace(10),
            TextFormField(
              controller: searchFilterController,
              decoration: InputDecoration(
                hintText: "Search For Note",
                border: OutlineInputBorder(gapPadding: 16),
                labelText: "Search",
                suffixIcon: searchFilterController.text.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          searchFilterController
                              .clear(); // Clear the text field
                          FocusScope.of(context)
                              .unfocus(); // Exit the text field (lose focus)
                          setState(() {
                            searchFilterString =
                                ""; // Optionally clear your search filter variable
                          });
                        },
                        child: Icon(Icons.clear),
                      )
                    : null, // Only show suffixIcon when there's text
              ),
              onChanged: (String value) {
                setState(() {
                  searchFilterString = value;
                });
              },
            ),
            addVerticalSpace(20),
            Expanded(
              child: FirebaseAnimatedList(
                  defaultChild: Center(
                    child: Text(
                      "Loading...",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  query: ref.child('UserData').child(_auth.currentUser!.uid),
                  itemBuilder: (context, snapshot, animation, index) {
                    String finalTitle = snapshot.child('Note').value.toString();

                    if (searchFilterString.isEmpty) {
                      return Column(
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 8.0),
                            tileColor: Colors.grey[900],
                            leading: Icon(Icons.note_add_rounded,
                                color: Colors.purple),
                            isThreeLine: true,
                            title: Text(
                              snapshot.child('Note').value.toString(),
                            ),
                            subtitle: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  snapshot.child('Date').value.toString(),
                                ),
                              ],
                            ),
                            trailing: SizedBox(
                              width: 80,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  InkWell(
                                      onTap: () {
                                        editNote(
                                            finalTitle,
                                            snapshot
                                                .child('Id')
                                                .value
                                                .toString());
                                      },
                                      child:
                                          Icon(Icons.edit, color: Colors.blue)),
                                  InkWell(
                                      onTap: () {
                                        deleteNote(
                                            finalTitle,
                                            snapshot
                                                .child('Id')
                                                .value
                                                .toString());
                                      },
                                      child: Icon(Icons.delete_forever,
                                          color: Colors.red)),
                                ],
                              ),
                            ),
                          ),
                          Divider(
                            color: Colors.blueGrey,
                          ),
                        ],
                      );
                    } else if (finalTitle.toLowerCase().toString().contains(
                        searchFilterString.toLowerCase().toString())) {
                      return ListTile(
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        tileColor: Colors.grey[900],
                        leading:
                            Icon(Icons.note_add_rounded, color: Colors.purple),
                        isThreeLine: true,
                        title: Text(
                          snapshot.child('Note').value.toString(),
                        ),
                        subtitle: Text(
                          snapshot.child('Date').value.toString(),
                        ),
                        trailing: SizedBox(
                          width: 80,
                          child: Row(
                            children: [
                              Icon(Icons.edit, color: Colors.blue),
                              Icon(Icons.delete_forever, color: Colors.red),
                            ],
                          ),
                        ),
                      );
                    } else {
                      return Column(
                        children: [
                          Container(
                            height: 400,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                  image: AssetImage("assets/images/image.png"),
                                  fit: BoxFit.cover),
                            ),
                          ),
                          addVerticalSpace(10),
                          Text(
                            "Sorry Search Not Found",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18),
                          )
                        ],
                      );
                    }
                  }),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) {
            return const MyPostScreen();
          }));
        },
        child: const Icon(Icons.add),
      ),
    );
  }

//edit code
  Future<void> editNote(String title, String id) async {
    editController.text = title;
    String day = DateTime.now().day.toString();
    String month = DateTime.now().month.toString();
    String year = DateTime.now().year.toString();
    String date = "$day/$month/$year";
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            shadowColor: Colors.white,
            icon: const Icon(Icons.edit_document),
            content: Container(
              child: TextFormField(
                controller: editController,
                decoration: InputDecoration(
                  contentPadding: EdgeInsets.all(20),
                  labelText: "Update Note",
                  border: OutlineInputBorder(gapPadding: 16),
                ),
                maxLines: 4,
              ),
            ),
            title: Center(
                child: Text(
              "update",
            )),
            actionsPadding: EdgeInsets.symmetric(horizontal: 20),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    "cancel",
                  )),
              TextButton(
                  onPressed: () {
                    ref
                        .child('UserData')
                        .child(_auth.currentUser!.uid)
                        .child(id)
                        .update({
                      'Id': id,
                      'Date': date,
                      'Note': editController.text.toString().trim(),
                    }).then((value) {
                      Utils().toastMessage("Note Updated!");
                    }).onError((error, stackTrace) {
                      Utils().toastMessage(error.toString());
                    });
                    Navigator.pop(context);
                  },
                  child: Text(
                    "update?",
                  )),
            ],
          );
        });
  }

//delete code
  Future<void> deleteNote(String title, String id) async {
    deleteController.text = title;
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            icon: Icon(Icons.delete),
            content: SizedBox(
              width: double.infinity,
              child: Text(title),
            ),
            title: Text("Delete Note"),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text("cancel")),
              TextButton(
                  onPressed: () {
                    ref
                        .child('UserData')
                        .child(_auth.currentUser!.uid.toString())
                        .child(id)
                        .remove()
                        .then((value) {
                      Utils().toastMessage("Note Deleted!");
                    }).onError((error, stackTrace) {
                      Utils().toastMessage(error.toString());
                    });
                    Navigator.pop(context);
                  },
                  child: Text("delete?")),
            ],
          );
        });
  }

  //exit confirmation msg
  Future<void> _confirmLogout() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return Center(
          child: AlertDialog(
            shadowColor: Colors.red,
            iconColor: Colors.black,
            backgroundColor: Colors.white,
            titleTextStyle: const TextStyle(color: Colors.black, fontSize: 20),
            icon: const Icon(Icons.cancel_presentation_sharp),
            title: const Text(
              "Confirm Logout",
            ),
            content: const Text(
              "Are you sure you want to logout?",
            ),
            contentTextStyle: TextStyle(color: Colors.black),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text(
                  "Cancel",
                  style: TextStyle(color: Colors.black),
                ),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();

                  await _auth.signOut();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const LoginScreen()),
                  );
                },
                child: const Text(
                  "Logout",
                  style: TextStyle(color: Colors.black, fontSize: 15),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  //btn confirmation msg
  Future<void> onClickBtn() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return Center(
          child: AlertDialog(
            shadowColor: Colors.red,
            iconColor: Colors.black,
            backgroundColor: Colors.white,
            titleTextStyle: const TextStyle(color: Colors.black, fontSize: 20),
            icon: const Icon(Icons.code_sharp),
            title: const Text(
              "About App",
            ),
            content: const Text(
              "This App Is Designed By Suraj Khot",
            ),
            contentTextStyle: TextStyle(color: Colors.black),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text(
                  "Ok",
                  style: TextStyle(color: Colors.black),
                ),
              ),
              TextButton(
                onPressed: () async {
                  const url = 'https://www.linkedin.com/in/khot-suraj';
                  if (await canLaunchUrl(Uri.parse(url))) {
                    await launchUrl(Uri.parse(url));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(url)),
                    );
                  }
                  Navigator.of(context).pop();
                },
                child: const Text(
                  "Visit Profile",
                  style: TextStyle(color: Colors.black, fontSize: 15),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
