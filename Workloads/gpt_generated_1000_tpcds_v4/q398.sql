WITH base AS (
    SELECT
        d.d_year,
        i.i_category,
        CASE WHEN cs.cs_net_profit > 1000 THEN 'High' ELSE 'Low' END AS profit_category,
        cs.cs_net_profit,
        cs.cs_quantity,
        cr.cr_net_loss,
        ws.ws_net_profit AS ws_net_profit,
        inv.inv_quantity_on_hand,
        we.web_company_name
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    JOIN warehouse w ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN ship_mode sm ON cs.cs_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN customer c ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd ON cs.cs_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN income_band ib ON hd.hd_income_band_sk = ib.ib_income_band_sk
    LEFT JOIN catalog_returns cr ON cr.cr_order_number = cs.cs_order_number
                               AND cr.cr_item_sk = cs.cs_item_sk
    LEFT JOIN reason r ON cr.cr_reason_sk = r.r_reason_sk
    LEFT JOIN inventory inv ON inv.inv_item_sk = i.i_item_sk
                           AND inv.inv_warehouse_sk = w.w_warehouse_sk
                           AND inv.inv_date_sk = d.d_date_sk
    JOIN web_sales ws ON ws.ws_item_sk = i.i_item_sk
                     AND ws.ws_sold_date_sk = d.d_date_sk
                     AND ws.ws_warehouse_sk = w.w_warehouse_sk
    JOIN web_site we ON ws.ws_web_site_sk = we.web_site_sk
    WHERE d.d_year = 2001
      AND hd.hd_buy_potential = '5001-10000'
      AND ib.ib_upper_bound >= 50000
      AND we.web_company_name = 'able'
      AND cs.cs_net_paid > 0
      AND EXISTS (
          SELECT 1
          FROM store_sales ss
          WHERE ss.ss_item_sk = cs.cs_item_sk
            AND ss.ss_sold_date_sk = d.d_date_sk
            AND ss.ss_sales_price > 0
      )
),
agg AS (
    SELECT
        d_year,
        i_category,
        profit_category,
        SUM(cs_net_profit) AS total_profit,
        SUM(cs_quantity) AS total_quantity,
        AVG(ws_net_profit) AS avg_web_profit,
        SUM(inv_quantity_on_hand) AS total_on_hand
    FROM base
    GROUP BY d_year, i_category, profit_category
)
SELECT
    profit_category,
    AVG(total_profit) AS avg_total_profit,
    SUM(total_quantity) AS sum_quantity
FROM agg
WHERE total_profit > 10000
GROUP BY profit_category
ORDER BY avg_total_profit DESC
