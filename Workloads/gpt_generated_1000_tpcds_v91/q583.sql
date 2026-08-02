WITH
    sales_agg AS (
        SELECT
            ws_order_number,
            ws_item_sk,
            ws_warehouse_sk,
            ws_web_site_sk,
            ws_bill_cdemo_sk,
            ws_bill_hdemo_sk,
            ws_ship_cdemo_sk,
            ws_ship_hdemo_sk,
            SUM(ws_ext_sales_price) AS total_sales,
            SUM(ws_net_profit) AS total_profit,
            COUNT(*) AS sales_cnt
        FROM web_sales
        WHERE ws_wholesale_cost > 50
          AND ws_list_price BETWEEN 70 AND 200
          AND ws_quantity >= 1
          AND ws_ship_mode_sk IS NOT NULL
        GROUP BY
            ws_order_number,
            ws_item_sk,
            ws_warehouse_sk,
            ws_web_site_sk,
            ws_bill_cdemo_sk,
            ws_bill_hdemo_sk,
            ws_ship_cdemo_sk,
            ws_ship_hdemo_sk
    ),
    inventory_agg AS (
        SELECT
            inv_warehouse_sk,
            SUM(inv_quantity_on_hand) AS total_inventory
        FROM inventory
        WHERE inv_quantity_on_hand > 0
        GROUP BY inv_warehouse_sk
    ),
    returns_agg AS (
        SELECT
            wr_order_number,
            COUNT(*) AS return_cnt,
            SUM(wr_return_amt) AS total_return_amount
        FROM web_returns
        WHERE wr_return_amt > 0
        GROUP BY wr_order_number
    ),
    unioned AS (
        SELECT
            w.w_warehouse_name AS warehouse_name,
            w.w_state AS warehouse_state,
            ws.total_sales,
            ws.total_profit,
            ws.sales_cnt,
            top_reason.top_reason_desc AS top_reason_desc,
            CASE WHEN cd.cd_gender = 'M' THEN 'Male' ELSE 'Female' END AS gender_label,
            hd.hd_buy_potential AS buy_potential,
            ws.total_sales / NULLIF(ws.sales_cnt, 0) AS avg_sales_per_order,
            inv_agg.total_inventory,
            (SELECT COUNT(DISTINCT ws2.ws_item_sk)
             FROM web_sales ws2
             WHERE ws2.ws_warehouse_sk = w.w_warehouse_sk) AS distinct_items_sold,
            RANK() OVER (PARTITION BY w.w_state ORDER BY ws.total_profit DESC) AS profit_rank_state,
            SUM(ws.total_profit) OVER (PARTITION BY w.w_state ORDER BY ws.total_profit DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_profit_state
        FROM sales_agg ws
        JOIN warehouse w
            ON ws.ws_warehouse_sk = w.w_warehouse_sk
        JOIN web_site ws_site
            ON ws.ws_web_site_sk = ws_site.web_site_sk
        JOIN customer_demographics cd
            ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
        JOIN household_demographics hd
            ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
        LEFT JOIN returns_agg ret
            ON ws.ws_order_number = ret.wr_order_number
        CROSS JOIN LATERAL (
            SELECT r.r_reason_desc AS top_reason_desc
            FROM web_returns wr
            JOIN reason r
                ON wr.wr_reason_sk = r.r_reason_sk
            WHERE wr.wr_order_number = ws.ws_order_number
            ORDER BY wr.wr_return_amt DESC
            LIMIT 1
        ) AS top_reason
        JOIN inventory_agg inv_agg
            ON w.w_warehouse_sk = inv_agg.inv_warehouse_sk
        WHERE w.w_state = 'CA'
          AND ws_site.web_manager = 'Harold Wilson'
          AND cd.cd_education_status = 'College'
          AND hd.hd_buy_potential = '5000-10000'
          AND inv_agg.total_inventory > 1000
          AND cd.cd_credit_rating IN ('Good', 'Excellent')
          AND NOT EXISTS (
              SELECT 1
              FROM web_returns wr3
              JOIN reason r3 ON wr3.wr_reason_sk = r3.r_reason_sk
              WHERE wr3.wr_order_number = ws.ws_order_number
                AND r3.r_reason_desc = 'Defective'
          )
        UNION
        SELECT
            w.w_warehouse_name AS warehouse_name,
            w.w_state AS warehouse_state,
            ws.total_sales,
            ws.total_profit,
            ws.sales_cnt,
            top_reason.top_reason_desc AS top_reason_desc,
            CASE WHEN cd.cd_gender = 'F' THEN 'Female' ELSE 'Male' END AS gender_label,
            hd.hd_buy_potential AS buy_potential,
            ws.total_sales / NULLIF(ws.sales_cnt, 0) AS avg_sales_per_order,
            inv_agg.total_inventory,
            (SELECT COUNT(DISTINCT ws2.ws_item_sk)
             FROM web_sales ws2
             WHERE ws2.ws_warehouse_sk = w.w_warehouse_sk) AS distinct_items_sold,
            RANK() OVER (PARTITION BY w.w_state ORDER BY ws.total_profit DESC) AS profit_rank_state,
            SUM(ws.total_profit) OVER (PARTITION BY w.w_state ORDER BY ws.total_profit DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_profit_state
        FROM sales_agg ws
        JOIN warehouse w
            ON ws.ws_warehouse_sk = w.w_warehouse_sk
        JOIN web_site ws_site
            ON ws.ws_web_site_sk = ws_site.web_site_sk
        JOIN customer_demographics cd
            ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
        JOIN household_demographics hd
            ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
        LEFT JOIN returns_agg ret
            ON ws.ws_order_number = ret.wr_order_number
        CROSS JOIN LATERAL (
            SELECT r.r_reason_desc AS top_reason_desc
            FROM web_returns wr
            JOIN reason r
                ON wr.wr_reason_sk = r.r_reason_sk
            WHERE wr.wr_order_number = ws.ws_order_number
            ORDER BY wr.wr_return_amt DESC
            LIMIT 1
        ) AS top_reason
        JOIN inventory_agg inv_agg
            ON w.w_warehouse_sk = inv_agg.inv_warehouse_sk
        WHERE w.w_state = 'TX'
          AND ws_site.web_manager = 'Marshall Conner'
          AND cd.cd_education_status = 'Graduate'
          AND hd.hd_buy_potential = '10000-20000'
          AND inv_agg.total_inventory > 500
          AND cd.cd_credit_rating IN ('Good')
          AND NOT EXISTS (
              SELECT 1
              FROM web_returns wr3
              JOIN reason r3 ON wr3.wr_reason_sk = r3.r_reason_sk
              WHERE wr3.wr_order_number = ws.ws_order_number
                AND r3.r_reason_desc = 'Defective'
          )
    )
SELECT
    warehouse_name,
    warehouse_state,
    total_sales,
    total_profit,
    sales_cnt,
    top_reason_desc,
    gender_label,
    buy_potential,
    avg_sales_per_order,
    total_inventory,
    distinct_items_sold,
    profit_rank_state,
    cumulative_profit_state
FROM unioned
ORDER BY total_profit DESC
OFFSET 0
LIMIT 100
