WITH uniq_item AS (
    SELECT DISTINCT i_item_sk, i_category, i_brand, i_manufact_id
    FROM item
),
joined AS (
    SELECT
        cs.cs_order_number,
        cs.cs_net_paid,
        cs.cs_net_profit,
        cr.cr_net_loss,
        ss.ss_net_paid,
        ss.ss_net_profit,
        sr.sr_net_loss,
        wr.wr_net_loss,
        i.i_category,
        i.i_brand,
        i.i_manufact_id,
        p.p_promo_name,
        p.p_discount_active,
        c.c_customer_id,
        w.w_warehouse_name,
        wp.wp_type,
        CASE WHEN sr.sr_return_quantity > 0 THEN 'RETURNED' ELSE 'NO_RETURN' END AS return_flag
    FROM uniq_item i
    JOIN catalog_sales cs            ON cs.cs_item_sk = i.i_item_sk
    JOIN customer c                  ON cs.cs_bill_customer_sk = c.c_customer_sk
    JOIN promotion p                 ON cs.cs_promo_sk = p.p_promo_sk
    JOIN warehouse w                 ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN catalog_returns cr          ON cr.cr_order_number = cs.cs_order_number
    JOIN store_sales ss              ON ss.ss_item_sk = i.i_item_sk AND ss.ss_customer_sk = c.c_customer_sk
    JOIN store_returns sr            ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN web_page wp                ON wp.wp_customer_sk = c.c_customer_sk
    JOIN web_returns wr              ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN inventory inv               ON inv.inv_item_sk = i.i_item_sk AND inv.inv_warehouse_sk = w.w_warehouse_sk
    WHERE i.i_manufact_id IN (479, 117)
      AND p.p_discount_active = 'Y'
      AND sr.sr_return_tax > 20
),
agg AS (
    SELECT
        i_category,
        p_promo_name,
        SUM(cs_net_paid)                         AS total_sales_paid,
        SUM(ss_net_paid)                         AS total_store_sales_paid,
        SUM(cs_net_profit) + SUM(ss_net_profit)  AS total_profit,
        SUM(cr_net_loss) + SUM(sr_net_loss) + SUM(wr_net_loss) AS total_return_loss,
        COUNT(DISTINCT c_customer_id)            AS distinct_customers,
        CASE WHEN SUM(cs_net_paid) > 0 THEN 'POSITIVE' ELSE 'NON_POSITIVE' END AS profit_sign
    FROM joined
    GROUP BY GROUPING SETS (
        (i_category, p_promo_name),
        (i_category),
        (p_promo_name),
        ()
    )
    HAVING SUM(cs_net_paid) > 10000
)
SELECT
    i_category,
    p_promo_name,
    total_sales_paid,
    total_store_sales_paid,
    total_profit,
    total_return_loss,
    distinct_customers,
    profit_sign,
    RANK() OVER (ORDER BY total_profit DESC) AS profit_rank
FROM agg
ORDER BY profit_rank
LIMIT 100
