WITH sampled_ss AS (
    SELECT *
    FROM store_sales TABLESAMPLE BERNOULLI (10)
    WHERE ss_quantity > 1
),
base AS (
    SELECT
        s.s_store_id,
        s.s_state,
        i.i_item_id,
        cc.cc_call_center_id,
        ss.ss_sold_date_sk,
        SUM(ss.ss_net_paid) AS total_net_paid,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_tickets,
        CASE
            WHEN SUM(ss.ss_net_paid) > (SELECT AVG(ss2.ss_net_paid) FROM store_sales ss2) THEN 'ABOVE_AVG'
            ELSE 'BELOW_AVG'
        END AS net_paid_category
    FROM sampled_ss ss
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN catalog_sales cs ON cs.cs_item_sk = i.i_item_sk
    JOIN call_center cc ON cs.cs_call_center_sk = cc.cc_call_center_sk
    WHERE i.i_manufact_id IN (294, 52, 625)
      AND s.s_state = 'TX'
      AND cc.cc_gmt_offset BETWEEN -5.00 AND -4.00
      AND cs.cs_ext_ship_cost > 500
    GROUP BY
        s.s_store_id,
        s.s_state,
        i.i_item_id,
        cc.cc_call_center_id,
        ss.ss_sold_date_sk
    HAVING SUM(ss.ss_net_paid) > 5000
)
SELECT
    b.s_store_id,
    b.s_state,
    b.i_item_id,
    b.cc_call_center_id,
    b.ss_sold_date_sk,
    b.total_net_paid,
    b.distinct_tickets,
    b.net_paid_category,
    RANK() OVER (PARTITION BY b.s_state ORDER BY b.total_net_paid DESC) AS state_rank
FROM base b
ORDER BY b.total_net_paid DESC
LIMIT 100
