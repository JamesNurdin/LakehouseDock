WITH ws_agg AS (
    SELECT
        w.w_warehouse_id,
        w.w_warehouse_name,
        w.w_city,
        CONCAT(w.w_warehouse_name, ' - ', w.w_city) AS warehouse_label,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(ws.ws_ext_sales_price) AS total_sales,
        COUNT(*) AS sales_cnt,
        CASE WHEN SUM(ws.ws_net_profit) > 0 THEN 'POS' ELSE 'NEG' END AS profit_flag
    FROM web_sales ws
    JOIN warehouse w ON ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN customer_demographics cd ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    WHERE regexp_like(cd.cd_gender, '^F')
      AND ws.ws_ext_sales_price > 0
      AND EXISTS (
          SELECT 1
          FROM catalog_returns cr
          JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
          WHERE cr.cr_warehouse_sk = w.w_warehouse_sk
            AND regexp_like(r.r_reason_desc, 'color')
      )
    GROUP BY w.w_warehouse_id, w.w_warehouse_name, w.w_city, CONCAT(w.w_warehouse_name, ' - ', w.w_city)
    HAVING SUM(ws.ws_ext_sales_price) > 10000
)
SELECT
    ws_agg.*,
    ROW_NUMBER() OVER (ORDER BY ws_agg.total_net_profit DESC) AS profit_rank
FROM ws_agg
ORDER BY profit_rank
LIMIT 100
