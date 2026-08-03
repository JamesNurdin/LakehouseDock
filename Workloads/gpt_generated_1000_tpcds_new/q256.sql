WITH intersect_customers AS (
    SELECT c.c_customer_id
    FROM store_sales ss
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    WHERE ss.ss_quantity > 2
    INTERSECT
    SELECT c.c_customer_id
    FROM web_sales ws
    JOIN customer c ON ws.ws_bill_customer_sk = c.c_customer_sk
    WHERE ws.ws_quantity > 2
),
joined_data AS (
    SELECT
        c.c_customer_id,
        d_store.d_year,
        i.i_brand,
        p.p_promo_name,
        ss.ss_net_profit            AS store_net_profit,
        ws.ws_net_profit            AS web_net_profit,
        wr.wr_net_loss,
        inv.inv_quantity_on_hand,
        cp.cp_catalog_number,
        r.r_reason_desc,
        ss.ss_quantity              AS store_qty,
        ws.ws_quantity              AS web_qty,
        CASE WHEN ss.ss_net_profit > 0 THEN 'Profitable' ELSE 'Loss' END AS store_profit_flag,
        ROW_NUMBER() OVER (PARTITION BY c.c_customer_id ORDER BY d_store.d_year DESC) AS rn
    FROM store_sales ss
    JOIN date_dim d_store ON ss.ss_sold_date_sk = d_store.d_date_sk
    JOIN time_dim t_store ON ss.ss_sold_time_sk = t_store.t_time_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    JOIN customer c ON ss.ss_customer_sk = c.c_customer_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk

    LEFT JOIN web_sales ws ON ss.ss_ticket_number = ws.ws_order_number
    LEFT JOIN date_dim d_ws ON ws.ws_sold_date_sk = d_ws.d_date_sk
    LEFT JOIN time_dim t_ws ON ws.ws_sold_time_sk = t_ws.t_time_sk
    LEFT JOIN web_returns wr ON ws.ws_order_number = wr.wr_order_number
    LEFT JOIN reason r ON wr.wr_reason_sk = r.r_reason_sk
    LEFT JOIN inventory inv ON i.i_item_sk = inv.inv_item_sk AND d_store.d_date_sk = inv.inv_date_sk
    LEFT JOIN catalog_page cp ON cp.cp_start_date_sk = d_store.d_date_sk
    LEFT JOIN date_dim d_wr ON wr.wr_returned_date_sk = d_wr.d_date_sk
    WHERE
        d_store.d_year = 2001
        AND i.i_brand = 'Brand#12'
        AND p.p_channel_email = 'N'
        AND c.c_preferred_cust_flag = 'Y'
        AND hd.hd_vehicle_count >= 1
)
SELECT
    jd.c_customer_id,
    jd.d_year,
    jd.i_brand,
    jd.p_promo_name,
    jd.store_net_profit,
    jd.web_net_profit,
    jd.wr_net_loss,
    jd.inv_quantity_on_hand,
    jd.store_profit_flag,
    RANK() OVER (PARTITION BY jd.d_year ORDER BY (jd.store_net_profit + COALESCE(jd.web_net_profit, 0)) DESC) AS profit_rank
FROM joined_data jd
JOIN intersect_customers ic ON jd.c_customer_id = ic.c_customer_id
WHERE jd.rn = 1
ORDER BY profit_rank ASC, jd.c_customer_id
LIMIT 100
