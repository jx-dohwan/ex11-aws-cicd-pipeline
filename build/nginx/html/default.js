$().ready(function(){
    let jsonData;

    /* 1. 교육생의 성적 리스트 조회 */
    function resultLoad(uid) {
        $("#resultArea tr").remove();
        if(!uid) uid = "";
        $.ajax({
            url: "/api/loadresult",
            method: "GET",
            data: { "uid": uid },
            dataType: "text",
            success: function(data) {
                let jsonList = JSON.parse(data);
                for(let row in jsonList) {
                    let $tr = $("<tr></tr>");
                    let idx = 0;
                    for(let key in jsonList[row]) {
                        let $td = $("<td></td>");
                        if(key === "fidx") {
                            idx = jsonList[row][key];
                            let $chkbox = $("<input />");
                            $chkbox.prop("type", "checkbox");
                            $chkbox.prop("name", "idx");
                            $chkbox.val(idx);
                            $td.append($chkbox);
                        } else {
                            let str = jsonList[row][key];
                            if(key === "fdate" && str) str = str.substr(0, 10);
                            $td.text(str);
                        }
                        $tr.append($td);
                    }
                    let $td = $("<td><a class=\"mp\" title=\"삭제\" style=\"cursor:pointer; color:#ff4500;\">Delete</a></td>");
                    $td.children("a").prop("idx", idx);
                    $tr.append($td);
                    $("#resultArea").append($tr);
                }
            },
            error: function(request, status, error){
                console.log("code:" + request.status + " message:" + request.responseText + " error:" + error);
            }
        });
    }

    // 최초 1회 자동 로드
    resultLoad();

    /* 2. 교육생 목록 조회 (Select Box) */
    $("#btnReload").on("click", function() {
        $("option").remove();
        $("select").append("<option value=\"\">==== 교육생 선택 ====</option>");
        $.ajax({
            url: "/api/members",
            method: "GET",
            dataType: "text",
            success: function(data) {
                let jsonList = JSON.parse(data);
                for(let row in jsonList){
                    let $option = $("<option></option>");
                    $option.val(jsonList[row]["fid"]);
                    $option.text(jsonList[row]["fname"]);
                    $("select").append($option);
                }
            },
            error: function(request, status, error){
                console.log("code:" + request.status + " message:" + request.responseText + " error:" + error);
            }
        });
    });
    $("#btnReload").click();
    $("#btnReload").prop("disabled", true);

    /* 3. 교육생 선택 변경 시 해당 교육생 성적만 조회 */
    $("select").on("change", function(ev) {
        resultLoad($(this).val());
    });

    /* 4. 점수 0~100 유효성 검사 */
    $(document).on("keyup", "#kor, #eng, #mat", function(){
        if($(this).val() < 0 || $(this).val() > 100) {
            alert("점수는 0점 이상 100점 이하로만 입력해야 합니다.");
            $(this).val(0);
        }
    });

    /* 5. 성적 등록 */
    $(document).on("click", "#btnLogin", function(){
        if($("#uid").val() === "") {
            alert("성적을 등록할 교육생을 선택하셔야 합니다.");
            $("#uid").focus();
            return;
        }
        if($("#kor").val() === "") {
            alert("국어 점수를 입력해주세요");
            $("#kor").focus();
            return;
        }
        if($("#eng").val() === "") {
            alert("영어 점수를 입력해주세요");
            $("#eng").focus();
            return;
        }
        if($("#mat").val() === "") {
            alert("수학 점수를 입력해주세요");
            $("#mat").focus();
            return;
        }

        // 신규 등록 시 idx 초기화 보장
        $("#idx").val("");

        $.ajax({
            url: "/api/insert",
            data: $("#appendForm").serialize(),
            method: "GET",
            dataType: "text",
            success: function(data) {
                let jsonData = JSON.parse(data);
                if(jsonData["msg"] === "success") {
                    resultLoad();
                    $("#kor").val(0);
                    $("#eng").val(0);
                    $("#mat").val(0);
                } else {
                    alert("성적 등록 중 에러가 발생하였습니다: " + data);
                }
            },
            error: function(request, status, error){
                console.log("code:" + request.status + " message:" + request.responseText + " error:" + error);
            }
        });
    });

    /* 6. 성적보기 버튼 */
    $(document).on("click", "#btnLoding", function(){
        resultLoad();
    });

    /* 7. 체크박스 전체 선택/해제 */
    $("#allChecked").on("change", function(ev) {
        $("input[name=idx]").prop("checked", this.checked);
    });

    /* 8. 개별 삭제 (Delete 링크) */
    $(document).on("click", ".mp", function(ev) {
        let idx = $(this).prop("idx");
        let $parentTR = $(this).parents("tr");
        let chk = $parentTR.children("td:first-child").children("input").prop("checked");
        
        if(!chk) {
            alert("삭제하려는 행의 체크박스를 먼저 선택해야 합니다.");
            return;
        }
        
        $.ajax({
            url: "/api/delete",
            method: "GET",
            dataType: "text",
            data: { "idx": idx },
            success: function(data) {
                let jsonData = JSON.parse(data);
                if(jsonData["msg"] === "success") {
                    $parentTR.remove();
                } else {
                    alert("성적 삭제 중 에러가 발생하였습니다: " + data);
                }
            },
            error: function(request, status, error){
                console.log("code:" + request.status + " message:" + request.responseText + " error:" + error);
            }
        });
    });

    /* 9. 일괄 삭제 버튼 (#btnChoDel) */
    $(document).on("click", "#btnChoDel", function(){
        let $checkedItems = $("input[name=idx]:checked");
        if($checkedItems.length === 0) {
            alert("삭제할 항목을 1개 이상 체크해 주세요.");
            return;
        }

        if(!confirm($checkedItems.length + "개의 항목을 삭제하시겠습니까?")) {
            return;
        }

        let deletePromises = [];
        $checkedItems.each(function() {
            let deleteIdx = $(this).val();
            let req = $.ajax({
                url: "/api/delete",
                method: "GET",
                data: { "idx": deleteIdx },
                dataType: "text"
            });
            deletePromises.push(req);
        });

        $.when.apply($, deletePromises).done(function() {
            alert("선택한 항목이 모두 삭제되었습니다.");
            resultLoad();
            $("#allChecked").prop("checked", false);
        }).fail(function() {
            alert("일괄 삭제 처리 중 오류가 발생했습니다.");
            resultLoad();
        });
    });

    /* 10. 수정을 위한 테이블 행 클릭 (폼 자동 채우기) */
    $(document).on("click", "#resultArea tr td:not(:last-child)", function(ev) {
        let $row = $(this).parent();
        let idx = $row.children("td:first-child").children("input").val();
        let uid = $row.children("td:nth-child(2)").text();
        let kor = $row.children("td:nth-child(5)").text();
        let eng = $row.children("td:nth-child(6)").text();
        let mat = $row.children("td:nth-child(7)").text();

        $("#idx").val(idx);
        $("#kor").val(kor);
        $("#eng").val(eng);
        $("#mat").val(mat);

        $("#uid option").each(function() {
            if($(this).val() === uid) {
                $(this).prop("selected", true);
            }
        });
    });

    /* 11. 성적 수정 */
    $(document).on("click", "#btnChoEdit", function(){
        if(!$("#idx").val()) {
            alert("수정할 성적 행을 아래 목록 테이블에서 먼저 클릭하여 선택하세요.");
            return;
        }
        $.ajax({
            url: "/api/edit",
            data: $("#appendForm").serialize(),
            method: "GET",
            dataType: "text",
            success: function(data) {
                let jsonData = JSON.parse(data);
                if(jsonData["msg"] === "success") {
                    alert("성적이 정상적으로 수정되었습니다.");
                    resultLoad();
                } else {
                    alert("성적 수정 중 에러가 발생하였습니다: " + data);
                }
            },
            error: function(request, status, error){
                console.log("code:" + request.status + " message:" + request.responseText + " error:" + error);
            }
        });
    });
});