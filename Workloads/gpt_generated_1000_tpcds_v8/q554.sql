WITH
    filtered_sales AS (
        SELECT
            cs.cs_order_number,
            cs.cs_bill_addr_sk,
            cs.cs_sold_date_sk,
            cs.cs_quantity,
            cs.cs_ext_sales_price,
            cs.cs_ext_discount_amt,
            cs.cs_coupon_amt,
            cs.cs_net_paid,
            ca.ca_state,
            d.d_year,
            d.d_day_name,
            d.d_fy_week_seq,
            ARRAY[cs.cs_quantity, CAST(cs.cs_ext_sales_price AS DOUBLE)] AS metrics_arr
        FROM catalog_sales cs
        LEFT JOIN customer_address ca
            ON cs.cs_bill_addr_sk = ca.ca_address_sk
        JOIN date_dim d
            ON cs.cs_sold_date_sk = d.d_date_sk
        WHERE cs.cs_quantity > 5
          AND cs.cs_ext_sales_price > 1000
          AND cs.cs_coupon_amt < 500
          AND ca.ca_state IN ('CA', 'TX', 'NY')
          AND d.d_year = 1998
          AND d.d_day_name = 'Friday'
          AND d.d_fy_week_seq IN (4, 6, 12)
    ),
    expanded_metrics AS (
        SELECT
            fs.cs_order_number,
            fs.ca_state,
            metric_value
        FROM filtered_sales fs
        CROSS JOIN UNNEST(fs.metrics_arr) AS t(metric_value)
    ),
    state_agg AS (
        SELECT
            ca_state,
            SUM(cs_net_paid) AS total_net_paid,
            COUNT(DISTINCT cs_order_number) AS order_cnt
        FROM filtered_sales
        GROUP BY ca_state
    ),
    state_rank AS (
        SELECT
            ca_state,
            total_net_paid,
            order_cnt,
            RANK() OVER (ORDER BY total_net_paid DESC) AS revenue_rank
        FROM state_agg
    ),
    order_intersect AS (
        SELECT cs_order_number
        FROM catalog_sales
        WHERE cs_ext_discount_amt > 200
        INTERSECT
        SELECT cs_order_number
        FROM catalog_sales
        WHERE cs_coupon_amt = 0
    ),
    order_excess AS (
        SELECT cs_order_number
        FROM catalog_sales
        WHERE cs_ext_discount_amt > 200
        EXCEPT
        SELECT cs_order_number
        FROM catalog_sales
        WHERE cs_coupon_amt = 0
    ),
    address_union AS (
        SELECT ca_address_sk FROM customer_address WHERE ca_state = 'CA'
        UNION
        SELECT ca_address_sk FROM customer_address WHERE ca_state = 'TX'
    )
SELECT
    fs.cs_order_number,
    fs.ca_state,
    fs.cs_net_paid,
    sr.revenue_rank,
    CASE WHEN oi.cs_order_number IS NOT NULL THEN 1 ELSE 0 END AS in_intersect,
    CASE WHEN oe.cs_order_number IS NOT NULL THEN 1 ELSE 0 END AS in_excess,
    em.metric_value
FROM filtered_sales fs
JOIN state_rank sr
    ON fs.ca_state = sr.ca_state
LEFT JOIN order_intersect oi
    ON fs.cs_order_number = oi.cs_order_number
LEFT JOIN order_excess oe
    ON fs.cs_order_number = oe.cs_order_number
LEFT JOIN expanded_metrics em
    ON fs.cs_order_number = em.cs_order_number
WHERE fs.cs_bill_addr_sk IN (SELECT ca_address_sk FROM address_union)
ORDER BY sr.revenue_rank, fs.cs_net_paid DESC
