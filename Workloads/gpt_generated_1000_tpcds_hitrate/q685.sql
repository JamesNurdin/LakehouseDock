WITH promo_agg AS (
    SELECT
        p.p_promo_sk,
        p.p_promo_id,
        p.p_end_date_sk,
        p.p_channel_details,
        w.w_warehouse_name,
        w.w_state,
        hd.hd_vehicle_count,
        ib.ib_upper_bound,
        COUNT(DISTINCT cs.cs_item_sk) AS distinct_items_sold,
        COUNT(DISTINCT ss.ss_ticket_number) AS distinct_store_tickets,
        SUM(cs.cs_net_paid) AS total_catalog_sales,
        SUM(ss.ss_net_paid) AS total_store_sales,
        SUM(ws.ws_net_paid) AS total_web_sales,
        CASE WHEN SUM(cs.cs_net_paid) > 100000 THEN 'HIGH' ELSE 'LOW' END AS sales_category
    FROM catalog_sales cs
    JOIN catalog_returns cr
        ON cr.cr_order_number = cs.cs_order_number
    JOIN promotion p
        ON cs.cs_promo_sk = p.p_promo_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN customer_address ca
        ON cs.cs_bill_addr_sk = ca.ca_address_sk
    JOIN warehouse w
        ON cs.cs_warehouse_sk = w.w_warehouse_sk
    JOIN income_band ib
        ON hd.hd_income_band_sk = ib.ib_income_band_sk
    JOIN store_sales ss
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
       AND ss.ss_addr_sk = ca.ca_address_sk
    JOIN store_returns sr
        ON sr.sr_ticket_number = ss.ss_ticket_number
       AND sr.sr_hdemo_sk = hd.hd_demo_sk
       AND sr.sr_addr_sk = ca.ca_address_sk
    JOIN web_sales ws
        ON ws.ws_bill_hdemo_sk = hd.hd_demo_sk
       AND ws.ws_bill_addr_sk = ca.ca_address_sk
    WHERE p.p_end_date_sk > 2450500                        -- predicate 1
      AND hd.hd_vehicle_count >= 2                         -- predicate 2
      AND ib.ib_upper_bound <= 80000                       -- predicate 3
      AND w.w_state = 'CA'                                 -- predicate 4
    GROUP BY
        p.p_promo_sk,
        p.p_promo_id,
        p.p_end_date_sk,
        p.p_channel_details,
        w.w_warehouse_name,
        w.w_state,
        hd.hd_vehicle_count,
        ib.ib_upper_bound
)
SELECT
    pa.p_promo_id,
    pa.total_catalog_sales,
    pa.total_store_sales,
    pa.total_web_sales,
    pa.distinct_items_sold,
    pa.distinct_store_tickets,
    pa.sales_category,
    pa.w_warehouse_name,
    pa.hd_vehicle_count,
    pa.ib_upper_bound,
    word,
    RANK() OVER (ORDER BY pa.total_catalog_sales DESC) AS sales_rank
FROM promo_agg pa
CROSS JOIN UNNEST(split(pa.p_channel_details, ' ')) AS t (word)
ORDER BY sales_rank
OFFSET 0 FETCH FIRST 100 ROWS ONLY
