WITH base AS (
    SELECT
        s.s_store_id,
        s.s_city,
        wsite.web_site_id,
        i.i_brand,
        d_sold.d_year,
        i.i_item_sk,
        ws.ws_net_profit,
        ws.ws_quantity
    FROM web_sales ws
    JOIN date_dim d_sold
        ON ws.ws_sold_date_sk = d_sold.d_date_sk
    JOIN time_dim t_sold
        ON ws.ws_sold_time_sk = t_sold.t_time_sk
    JOIN item i
        ON ws.ws_item_sk = i.i_item_sk
    JOIN customer c
        ON ws.ws_bill_customer_sk = c.c_customer_sk
    JOIN customer_demographics cd
        ON ws.ws_bill_cdemo_sk = cd.cd_demo_sk
    JOIN household_demographics hd
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
    JOIN ship_mode sm
        ON ws.ws_ship_mode_sk = sm.sm_ship_mode_sk
    JOIN web_site wsite
        ON ws.ws_web_site_sk = wsite.web_site_sk
    JOIN promotion p
        ON ws.ws_promo_sk = p.p_promo_sk
    JOIN inventory inv
        ON inv.inv_item_sk = i.i_item_sk
        AND inv.inv_date_sk = d_sold.d_date_sk
    JOIN store_returns sr
        ON sr.sr_item_sk = i.i_item_sk
        AND sr.sr_returned_date_sk = d_sold.d_date_sk
    JOIN store s
        ON sr.sr_store_sk = s.s_store_sk
    JOIN date_dim d_store_closed
        ON s.s_closed_date_sk = d_store_closed.d_date_sk
    JOIN call_center cc
        ON cc.cc_closed_date_sk = d_store_closed.d_date_sk
    JOIN catalog_page cp
        ON cp.cp_end_date_sk = d_store_closed.d_date_sk
),
agg AS (
    SELECT
        b.s_store_id,
        b.s_city,
        b.web_site_id,
        b.i_brand,
        b.d_year,
        b.i_item_sk,
        SUM(b.ws_net_profit) AS total_net_profit,
        SUM(b.ws_quantity) AS total_quantity,
        CASE WHEN SUM(b.ws_net_profit) > 50000 THEN 'High' ELSE 'Low' END AS profit_category,
        (SELECT SUM(ws3.ws_net_profit)
         FROM web_sales ws3
         WHERE ws3.ws_item_sk = b.i_item_sk) AS item_total_profit
    FROM base b
    WHERE b.s_store_id NOT IN (
        SELECT s2.s_store_id
        FROM store s2
        WHERE s2.s_state = 'ZZ'
    )
    GROUP BY b.s_store_id, b.s_city, b.web_site_id, b.i_brand, b.d_year, b.i_item_sk
    HAVING SUM(b.ws_quantity) > 100
),
ranked AS (
    SELECT
        a.*, 
        LAG(total_net_profit) OVER (PARTITION BY s_store_id ORDER BY d_year) AS prev_year_profit,
        ROW_NUMBER() OVER (PARTITION BY s_store_id ORDER BY total_net_profit DESC) AS rn
    FROM agg a
)
SELECT
    s_store_id,
    s_city,
    web_site_id,
    i_brand,
    d_year,
    total_net_profit,
    total_quantity,
    profit_category,
    prev_year_profit,
    item_total_profit
FROM ranked
WHERE rn <= 5
ORDER BY total_net_profit DESC
LIMIT 100
