WITH filtered_returns AS (
    SELECT
        ws.ws_sold_time_sk,
        ws.ws_web_site_sk,
        wr.wr_net_loss,
        r.r_reason_desc,
        w.web_company_name
    FROM web_returns wr
    JOIN web_sales ws
        ON wr.wr_item_sk = ws.ws_item_sk
       AND wr.wr_order_number = ws.ws_order_number
    JOIN reason r
        ON wr.wr_reason_sk = r.r_reason_sk
    JOIN web_site w
        ON ws.ws_web_site_sk = w.web_site_sk
    WHERE regexp_like(r.r_reason_desc, '(?i)defect|damage')
      AND w.web_company_name LIKE 'A%'
)
SELECT
    t.t_hour AS return_hour,
    substring(fr.web_company_name, 1, 3) AS company_prefix,
    COUNT(*) AS returns_count,
    SUM(fr.wr_net_loss) AS total_net_loss,
    round(avg(fr.wr_net_loss), 2) AS avg_net_loss,
    regexp_extract(fr.r_reason_desc, '(defect|damage)', 1) AS matched_reason
FROM filtered_returns fr
JOIN time_dim t
    ON fr.ws_sold_time_sk = t.t_time_sk
GROUP BY
    t.t_hour,
    substring(fr.web_company_name, 1, 3),
    regexp_extract(fr.r_reason_desc, '(defect|damage)', 1)
ORDER BY total_net_loss DESC
LIMIT 20
