WITH ss_agg AS (
    SELECT
        ss_item_sk,
        ss_sold_date_sk,
        SUM(ss_ext_sales_price) AS total_sales,
        SUM(ss_net_profit) AS total_profit
    FROM store_sales
    GROUP BY ss_item_sk, ss_sold_date_sk
),
joined AS (
    SELECT
        c.c_customer_id,
        ca.ca_state,
        p.p_promo_id,
        ss_agg.total_sales,
        cs.cs_ext_sales_price AS catalog_sales,
        ss_agg.total_profit,
        sr.sr_return_quantity,
        hd.hd_dep_count,
        hd.hd_buy_potential
    FROM ss_agg
    JOIN store_sales ss
        ON ss_agg.ss_item_sk = ss.ss_item_sk
       AND ss_agg.ss_sold_date_sk = ss.ss_sold_date_sk
    JOIN time_dim td
        ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN customer c
        ON ss.ss_customer_sk = c.c_customer_sk
    JOIN customer_address ca
        ON ss.ss_addr_sk = ca.ca_address_sk
    JOIN household_demographics hd
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
    JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
    JOIN catalog_sales cs
        ON cs.cs_bill_customer_sk = c.c_customer_sk
       AND cs.cs_bill_hdemo_sk = hd.hd_demo_sk
       AND cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN call_center cc
        ON cs.cs_call_center_sk = cc.cc_call_center_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN web_page wp
        ON wp.wp_customer_sk = c.c_customer_sk
    JOIN web_returns wr
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
       AND wr.wr_refunded_customer_sk = c.c_customer_sk
    WHERE
        ca.ca_state = 'TX'
        AND hd.hd_dep_count >= 2
        AND hd.hd_buy_potential = '5001-10000'
        AND p.p_discount_active = 'Y'
        AND cc.cc_country = 'United States'
        AND cs.cs_sold_date_sk BETWEEN 2450000 AND 2450100
        AND EXISTS (
            SELECT 1
            FROM catalog_sales cs2
            WHERE cs2.cs_bill_customer_sk = c.c_customer_sk
              AND cs2.cs_ext_discount_amt > 100
        )
),
agg AS (
    SELECT
        c_customer_id,
        ca_state,
        p_promo_id,
        hd_dep_count,
        SUM(total_sales) AS agg_sales,
        SUM(catalog_sales) AS catalog_sales,
        SUM(total_profit) AS agg_profit,
        COUNT(DISTINCT sr_return_quantity) AS return_qty
    FROM joined
    GROUP BY ROLLUP (ca_state, p_promo_id, c_customer_id, hd_dep_count)
)
SELECT
    c_customer_id,
    ca_state,
    p_promo_id,
    hd_dep_count,
    agg_sales,
    catalog_sales,
    agg_profit,
    return_qty,
    CASE
        WHEN hd_dep_count = 0 THEN 'No dependents'
        WHEN hd_dep_count BETWEEN 1 AND 3 THEN 'Few dependents'
        ELSE 'Many dependents'
    END AS dep_category,
    RANK() OVER (PARTITION BY ca_state ORDER BY agg_sales DESC) AS state_sales_rank
FROM agg
WHERE agg_sales IS NOT NULL
ORDER BY agg_sales DESC
LIMIT 100
