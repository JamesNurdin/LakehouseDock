WITH base AS (
    SELECT
        wr.wr_returned_date_sk,
        t.t_time,
        wr.wr_item_sk,
        i.i_product_name,
        inv.inv_quantity_on_hand,
        p.p_discount_active,
        wr.wr_refunded_customer_sk AS cust_sk,
        c.c_first_name,
        c.c_last_name,
        hd.hd_income_band_sk,
        wp.wp_url,
        r.r_reason_desc,
        wr.wr_net_loss AS web_net_loss,
        sr.sr_net_loss AS store_net_loss
    FROM web_returns wr
    JOIN time_dim t
      ON wr.wr_returned_time_sk = t.t_time_sk
    JOIN item i
      ON wr.wr_item_sk = i.i_item_sk
    JOIN inventory inv
      ON inv.inv_item_sk = i.i_item_sk
    JOIN promotion p
      ON p.p_item_sk = i.i_item_sk
    JOIN customer c
      ON wr.wr_refunded_customer_sk = c.c_customer_sk
    JOIN household_demographics hd
      ON wr.wr_refunded_hdemo_sk = hd.hd_demo_sk
    JOIN web_page wp
      ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN reason r
      ON wr.wr_reason_sk = r.r_reason_sk
    LEFT JOIN store_returns sr
      ON sr.sr_item_sk = i.i_item_sk
     AND sr.sr_customer_sk = c.c_customer_sk
    WHERE t.t_hour BETWEEN 8 AND 18
      AND i.i_current_price > 20
      AND inv.inv_quantity_on_hand > 0
      AND p.p_discount_active = 'Y'
      AND c.c_preferred_cust_flag = 'Y'
)
SELECT
    cust_sk,
    c_first_name,
    c_last_name,
    SUM(web_net_loss) AS total_web_loss,
    SUM(COALESCE(store_net_loss, 0)) AS total_store_loss,
    COUNT(*) AS web_return_count,
    AVG(inv_quantity_on_hand) AS avg_inventory_on_hand,
    MAX(t_time) AS last_return_time,
    RANK() OVER (ORDER BY SUM(web_net_loss) DESC) AS web_loss_rank,
    CASE
        WHEN SUM(web_net_loss) > SUM(COALESCE(store_net_loss, 0)) THEN 'WEB > STORE'
        ELSE 'STORE >= WEB'
    END AS loss_comparison
FROM base
GROUP BY cust_sk, c_first_name, c_last_name
HAVING SUM(web_net_loss) > 100
ORDER BY web_loss_rank
LIMIT 20
