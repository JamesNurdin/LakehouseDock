WITH sales_returns AS (
    SELECT
        ws.ws_order_number,
        ws.ws_sold_date_sk,
        ws.ws_ship_date_sk,
        ws.ws_item_sk,
        ws.ws_bill_customer_sk,
        ws.ws_bill_cdemo_sk,
        ws.ws_bill_hdemo_sk,
        ws.ws_ship_customer_sk,
        ws.ws_ship_cdemo_sk,
        ws.ws_ship_hdemo_sk,
        ws.ws_promo_sk,
        ws.ws_ship_mode_sk,
        ws.ws_web_page_sk,
        ws.ws_web_site_sk,
        ws.ws_net_profit,
        ws.ws_quantity,
        wr.wr_return_quantity,
        wr.wr_return_amt,
        wr.wr_reason_sk
    FROM web_sales ws
    FULL OUTER JOIN web_returns wr
      ON ws.ws_order_number = wr.wr_order_number
     AND ws.ws_item_sk = wr.wr_item_sk
),
joined_data AS (
    SELECT
        cc.cc_division,
        cc.cc_name,
        d_ship.d_year,
        c.c_customer_sk,
        c.c_customer_id,
        sr.ws_net_profit,
        sr.ws_quantity,
        sr.ws_order_number,
        sr.ws_ship_date_sk,
        sr.wr_reason_sk,
        sm.sm_carrier,
        p.p_discount_active,
        cd.cd_credit_rating,
        hd.hd_buy_potential
    FROM sales_returns sr
    JOIN customer c
      ON sr.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
      ON sr.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
      ON sr.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN web_page wp
      ON sr.ws_web_page_sk = wp.wp_web_page_sk
    JOIN web_site wsit
      ON sr.ws_web_site_sk = wsit.web_site_sk
    JOIN ship_mode sm
      ON sr.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN promotion p
      ON sr.ws_promo_sk = p.p_promo_sk
    LEFT JOIN reason r
      ON sr.wr_reason_sk = r.r_reason_sk
    LEFT JOIN date_dim d_ship
      ON sr.ws_ship_date_sk = d_ship.d_date_sk
    LEFT JOIN call_center cc
      ON cc.cc_open_date_sk = d_ship.d_date_sk
    LEFT JOIN inventory inv
      ON inv.inv_date_sk = d_ship.d_date_sk
    WHERE
        d_ship.d_year = 2001
        AND cc.cc_division IN (1, 2, 3)
        AND hd.hd_buy_potential = 'Medium'
        AND sm.sm_carrier = 'UPS'
        AND p.p_discount_active = 'Y'
        AND cd.cd_credit_rating = 'Good'
        AND EXISTS (
            SELECT 1
            FROM promotion p2
            WHERE p2.p_promo_sk = sr.ws_promo_sk
              AND p2.p_discount_active = 'Y'
        )
),
agg_data AS (
    SELECT
        cc_division,
        cc_name,
        d_year,
        c_customer_sk,
        c_customer_id,
        SUM(ws_net_profit) AS total_net_profit,
        SUM(COALESCE(ws_quantity, 0)) AS total_quantity,
        COUNT(DISTINCT ws_order_number) AS order_count
    FROM joined_data
    GROUP BY
        cc_division,
        cc_name,
        d_year,
        c_customer_sk,
        c_customer_id
    HAVING
        SUM(ws_net_profit) > 0
)
SELECT
    agg.cc_division,
    agg.cc_name,
    agg.d_year,
    agg.c_customer_id,
    agg.total_net_profit,
    agg.total_quantity,
    agg.order_count,
    RANK() OVER (PARTITION BY agg.cc_division ORDER BY agg.total_net_profit DESC) AS profit_rank_by_division,
    CASE
        WHEN agg.total_net_profit >= 10000 THEN 'High'
        WHEN agg.total_net_profit >= 5000 THEN 'Medium'
        ELSE 'Low'
    END AS profit_category,
    (
        SELECT MAX(ws3.ws_net_profit)
        FROM web_sales ws3
        WHERE ws3.ws_bill_customer_sk = agg.c_customer_sk
    ) AS max_customer_net_profit
FROM agg_data agg
ORDER BY agg.total_net_profit DESC, profit_rank_by_division ASC
LIMIT 100
