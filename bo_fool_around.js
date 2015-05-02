$(document).ready(function() {
    $("#bo_photo").hover(function(){$(this).attr("src", "images/profile-pics/poptocat.png");}, function(){$(this).attr("src", "images/profile-pics/cui-bo325.png");});
    $("#bo_name").hover(function(){$(this).text("Red Cubit Dog");}, function(){$(this).text("Boxuan Cui");});
    $("#bo_title").hover(function(){$(this).text("and things change when you mouseover me");}, function(){$(this).text("Senior Knowledge Analyst");});
});
