WITH filtered_pages AS (
    SELECT
        cp.cp_catalog_page_id,
        cp.cp_department,
        cp.cp_catalog_page_number,
        d.d_date,
        d.d_date_sk
    FROM catalog_page cp
    JOIN date_dim d ON cp.cp_start_date_sk = d.d_date_sk
    WHERE regexp_like(cp.cp_catalog_page_id, '^AAAAAAA[AJ].*')
      AND cp.cp_department LIKE 'DEPARTMENT'
),
 daily_sales AS (
    SELECT
        d2.d_date,
        SUM(ss.ss_ext_sales_price) AS store_sales_amount,
        SUM(ws.ws_ext_sales_price) AS web_sales_amount,
        SUM(ss.ss_net_profit) + SUM(ws.ws_net_profit) AS total_profit
    FROM store_sales ss
    JOIN web_sales ws ON ss.ss_sold_date_sk = ws.ws_sold_date_sk
    JOIN date_dim d2 ON ss.ss_sold_date_sk = d2.d_date_sk
    GROUP BY d2.d_date
)
SELECT
    fp.d_date,
    cc.cc_name,
    cc.cc_manager,
    CASE
        WHEN ds.total_profit > (
            SELECT AVG(ss2.ss_net_profit + ws2.ws_net_profit)
            FROM store_sales ss2
            JOIN web_sales ws2 ON ss2.ss_sold_date_sk = ws2.ws_sold_date_sk
        ) THEN 'High'
        ELSE 'Low'
    END AS profit_category,
    ds.store_sales_amount,
    ds.web_sales_amount,
    ds.total_profit,
    regexp_extract(fp.cp_catalog_page_id, 'AAAAAAA([A-Z])', 1) AS page_id_letter,
    CONCAT(cc.cc_manager, ' - ', fp.cp_department) AS manager_dept
FROM filtered_pages fp
JOIN date_dim d ON fp.d_date_sk = d.d_date_sk
JOIN call_center cc ON cc.cc_open_date_sk = d.d_date_sk
JOIN daily_sales ds ON ds.d_date = fp.d_date
WHERE cc.cc_class = 'large'
  AND regexp_like(cc.cc_manager, '^J')
ORDER BY ds.total_profit DESC
LIMIT 100
