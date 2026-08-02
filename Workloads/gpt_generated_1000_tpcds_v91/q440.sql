WITH cs_agg AS (
    SELECT
        cs_bill_customer_sk AS customer_sk,
        cs_call_center_sk AS call_center_sk,
        SUM(cs_net_paid) AS metric1,
        SUM(cs_quantity) AS metric2,
        COUNT(*) AS metric3
    FROM catalog_sales
    WHERE cs_sold_date_sk BETWEEN 2450816 AND 2451244
      AND cs_wholesale_cost > 10
      AND cs_ext_tax > 0
    GROUP BY cs_bill_customer_sk, cs_call_center_sk
),
wr_agg AS (
    SELECT
        wr_refunded_customer_sk AS customer_sk,
        CAST(NULL AS integer) AS call_center_sk,
        SUM(wr_return_amt) AS metric1,
        SUM(wr_return_quantity) AS metric2,
        COUNT(*) AS metric3
    FROM web_returns
    WHERE wr_returned_date_sk BETWEEN 2450816 AND 2451244
      AND wr_return_amt > 0
      AND wr_return_tax > 5
    GROUP BY wr_refunded_customer_sk
),
union_agg AS (
    SELECT customer_sk, call_center_sk, metric1, metric2, metric3
    FROM cs_agg
    UNION DISTINCT
    SELECT customer_sk, call_center_sk, metric1, metric2, metric3
    FROM wr_agg
),
full_inventory_warehouse AS (
    SELECT
        inv.inv_warehouse_sk,
        inv.inv_quantity_on_hand,
        wh.w_warehouse_name,
        wh.w_city,
        wh.w_state,
        wh.w_gmt_offset
    FROM inventory inv
    FULL OUTER JOIN warehouse wh
        ON inv.inv_warehouse_sk = wh.w_warehouse_sk
)
SELECT
    ua.customer_sk,
    c.c_first_name,
    c.c_last_name,
    cd.cd_gender,
    hd.hd_buy_potential,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    cc.cc_name,
    cc.cc_state,
    ca.ca_state AS address_state,
    wp.wp_web_page_id,
    SUM(ua.metric1) AS sum_metric1,
    SUM(ua.metric2) AS sum_metric2,
    COUNT(DISTINCT ua.metric3) AS distinct_metric3,
    MIN(ua.metric1) AS min_metric1,
    MAX(ua.metric2) AS max_metric2,
    (SELECT MAX(ib2.ib_upper_bound) FROM income_band ib2) AS max_income_upper_bound,
    (SELECT COUNT(*) FROM full_inventory_warehouse fiw WHERE fiw.inv_quantity_on_hand > 0) AS fiw_positive_qty_count
FROM union_agg ua
JOIN customer c
    ON ua.customer_sk = c.c_customer_sk
LEFT JOIN customer_demographics cd
    ON c.c_current_cdemo_sk = cd.cd_demo_sk
LEFT JOIN household_demographics hd
    ON c.c_current_hdemo_sk = hd.hd_demo_sk
LEFT JOIN income_band ib
    ON hd.hd_income_band_sk = ib.ib_income_band_sk
LEFT JOIN customer_address ca
    ON c.c_current_addr_sk = ca.ca_address_sk
LEFT JOIN call_center cc
    ON ua.call_center_sk = cc.cc_call_center_sk
LEFT JOIN web_page wp
    ON wp.wp_customer_sk = c.c_customer_sk
WHERE c.c_birth_year BETWEEN 1950 AND 1960
  AND hd.hd_buy_potential = '>10000'
  AND cc.cc_state = 'CA'
  AND ib.ib_upper_bound > 100000
  AND ca.ca_state = 'TX'
  AND EXISTS (
        SELECT 1
        FROM web_page wp2
        WHERE wp2.wp_customer_sk = c.c_customer_sk
          AND wp2.wp_type = 'Content'
    )
GROUP BY
    ua.customer_sk,
    c.c_first_name,
    c.c_last_name,
    cd.cd_gender,
    hd.hd_buy_potential,
    ib.ib_lower_bound,
    ib.ib_upper_bound,
    cc.cc_name,
    cc.cc_state,
    ca.ca_state,
    wp.wp_web_page_id
ORDER BY sum_metric1 DESC
LIMIT 100
