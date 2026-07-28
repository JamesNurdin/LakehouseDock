WITH sales_agg AS (
    SELECT
        i.i_category,
        i.i_brand,
        p.p_promo_name,
        SUM(ws.ws_net_profit) AS total_net_profit,
        SUM(wr.wr_net_loss) AS total_net_loss,
        SUM(ws.ws_quantity) AS total_quantity,
        COUNT(DISTINCT ws.ws_order_number) AS order_cnt
    FROM web_sales ws
    JOIN web_returns wr
      ON ws.ws_order_number = wr.wr_order_number
    JOIN item i
      ON ws.ws_item_sk = i.i_item_sk
    JOIN time_dim td
      ON ws.ws_sold_time_sk = td.t_time_sk
    JOIN promotion p
      ON ws.ws_promo_sk = p.p_promo_sk
    JOIN reason r
      ON wr.wr_reason_sk = r.r_reason_sk
    JOIN customer c
      ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
      ON c.c_current_cdemo_sk = cd.cd_demo_sk
    LEFT JOIN inventory inv
      ON i.i_item_sk = inv.inv_item_sk
      AND inv.inv_date_sk = ws.ws_sold_date_sk
    WHERE c.c_preferred_cust_flag = 'Y'
      AND c.c_birth_year BETWEEN 1950 AND 1970
      AND i.i_current_price > 20
      AND COALESCE(inv.inv_quantity_on_hand, 0) > 0
    GROUP BY i.i_category, i.i_brand, p.p_promo_name
)
SELECT
    i_category,
    i_brand,
    p_promo_name,
    total_net_profit,
    total_net_loss,
    total_quantity,
    order_cnt,
    (total_net_profit - total_net_loss) / NULLIF(total_quantity, 0) AS profit_margin
FROM sales_agg
WHERE (total_net_profit - total_net_loss) / NULLIF(total_quantity, 0) > 0.10
ORDER BY profit_margin DESC
LIMIT 100
