WITH
    sales_agg AS (
        SELECT
            d.d_year,
            p.p_promo_name,
            SUM(cs.cs_net_paid)                AS total_net_paid,
            SUM(cs.cs_quantity)                AS total_quantity,
            cc.cc_state,
            ca.ca_county,
            hd.hd_vehicle_count
        FROM catalog_sales cs
        JOIN date_dim d               ON cs.cs_sold_date_sk = d.d_date_sk
        JOIN promotion p               ON cs.cs_promo_sk = p.p_promo_sk
        JOIN call_center cc            ON cs.cs_call_center_sk = cc.cc_call_center_sk
        JOIN customer_address ca      ON cs.cs_bill_addr_sk = ca.ca_address_sk
        JOIN household_demographics hd ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
        WHERE d.d_year = 2001
          AND p.p_discount_active = 'Y'
          AND cs.cs_ext_tax > 100
          AND cs.cs_coupon_amt BETWEEN 100 AND 2000
          AND cs.cs_quantity > 0
          AND cc.cc_state = 'CA'
          AND ca.ca_county = 'York County'
          AND hd.hd_vehicle_count >= 2
        GROUP BY d.d_year, p.p_promo_name, cc.cc_state, ca.ca_county, hd.hd_vehicle_count
    ),
    returns_agg AS (
        SELECT
            r.r_reason_desc,
            SUM(sr.sr_net_loss)               AS total_net_loss,
            d.d_year,
            cc2.cc_state,
            ca2.ca_county,
            hd2.hd_vehicle_count
        FROM store_returns sr
        JOIN date_dim d               ON sr.sr_returned_date_sk = d.d_date_sk
        JOIN reason r                  ON sr.sr_reason_sk = r.r_reason_sk
        JOIN call_center cc2           ON cc2.cc_closed_date_sk = d.d_date_sk
        JOIN web_sales ws              ON ws.ws_sold_date_sk = d.d_date_sk
        JOIN customer_address ca2     ON ws.ws_bill_addr_sk = ca2.ca_address_sk
        JOIN household_demographics hd2 ON ws.ws_bill_hdemo_sk = hd2.hd_demo_sk
        JOIN catalog_returns cr       ON cr.cr_returned_date_sk = d.d_date_sk
        WHERE d.d_year = 2001
          AND sr.sr_return_quantity > 0
          AND sr.sr_return_amt > 0
          AND r.r_reason_desc LIKE '%damage%'
          AND sr.sr_fee < 100
          AND cc2.cc_state = 'CA'
          AND ca2.ca_county = 'York County'
          AND hd2.hd_vehicle_count >= 2
        GROUP BY r.r_reason_desc, d.d_year, cc2.cc_state, ca2.ca_county, hd2.hd_vehicle_count
    ),
    combined AS (
        SELECT
            'sales'   AS metric_type,
            CAST(d_year AS VARCHAR)                AS year,
            p_promo_name                            AS label,
            total_net_paid                          AS metric_value
        FROM sales_agg
        UNION ALL
        SELECT
            'return'  AS metric_type,
            CAST(d_year AS VARCHAR)                AS year,
            r_reason_desc                           AS label,
            total_net_loss                          AS metric_value
        FROM returns_agg
    )
SELECT
    metric_type,
    AVG(metric_value) AS avg_metric_value
FROM combined
WHERE metric_value > 0
GROUP BY metric_type
HAVING AVG(metric_value) > 5000
ORDER BY avg_metric_value DESC
LIMIT 100
