WITH base AS (
    SELECT
        td.t_hour,
        i.i_category,
        ss.ss_net_profit,
        cs.cs_net_profit,
        wr.wr_net_loss,
        cs.cs_order_number,
        ss.ss_ticket_number,
        wr.wr_return_amt,
        p.p_cost,
        pc.promo_count
    FROM tpcds.time_dim td
    JOIN tpcds.store_sales ss
        ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN tpcds.catalog_sales cs
        ON cs.cs_sold_time_sk = td.t_time_sk
    JOIN tpcds.web_returns wr
        ON wr.wr_returned_time_sk = td.t_time_sk
    JOIN tpcds.item i
        ON i.i_item_sk = ss.ss_item_sk
       AND i.i_item_sk = cs.cs_item_sk
       AND i.i_item_sk = wr.wr_item_sk
    JOIN tpcds.household_demographics hd
        ON hd.hd_demo_sk = ss.ss_hdemo_sk
       AND hd.hd_demo_sk = cs.cs_bill_hdemo_sk
    JOIN tpcds.promotion p
        ON p.p_promo_sk = ss.ss_promo_sk
       AND p.p_promo_sk = cs.cs_promo_sk
       AND p.p_item_sk = i.i_item_sk
    JOIN tpcds.web_page wp
        ON wp.wp_web_page_sk = wr.wr_web_page_sk
    CROSS JOIN LATERAL (
        SELECT COUNT(*) AS promo_count
        FROM tpcds.promotion p2
        WHERE p2.p_item_sk = i.i_item_sk
    ) AS pc
    WHERE td.t_shift = 'first'
      AND i.i_brand = 'Brand#34'
      AND hd.hd_vehicle_count >= 2
      AND EXISTS (
          SELECT 1
          FROM tpcds.promotion p3
          WHERE p3.p_item_sk = i.i_item_sk
            AND p3.p_discount_active = 'Y'
      )
)
SELECT
    t_hour,
    i_category,
    SUM(COALESCE(ss_net_profit, 0) + COALESCE(cs_net_profit, 0) - COALESCE(wr_net_loss, 0)) AS total_net_profit,
    COUNT(DISTINCT cs_order_number) AS num_catalog_orders,
    COUNT(DISTINCT ss_ticket_number) AS num_store_tickets,
    SUM(wr_return_amt) AS total_return_amount,
    MAX(promo_count) AS promo_count,
    MAX(p_cost) AS max_promo_cost
FROM base
GROUP BY GROUPING SETS (
    (t_hour, i_category),
    (t_hour),
    (i_category),
    ()
)
ORDER BY total_net_profit DESC
LIMIT 100
