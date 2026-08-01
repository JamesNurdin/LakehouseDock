WITH returns_agg AS (
    SELECT
        d_ret.d_year,
        d_ret.d_month_seq,
        wp.wp_type,
        cp.cp_department,
        COUNT(*) AS return_cnt,
        SUM(wr.wr_return_amt) AS total_return_amt,
        AVG(wr.wr_return_amt) AS avg_return_amt,
        SUM(wr.wr_fee) AS total_fee,
        MAX(wr.wr_net_loss) AS max_net_loss,
        MIN(wr.wr_net_loss) AS min_net_loss,
        SUM(CASE WHEN wr.wr_fee > 20 THEN wr.wr_fee ELSE 0 END) AS high_fee_total,
        SUM(CASE WHEN wr.wr_fee <= 20 THEN wr.wr_fee ELSE 0 END) AS low_fee_total
    FROM web_returns wr
    JOIN date_dim d_ret ON wr.wr_returned_date_sk = d_ret.d_date_sk
    JOIN web_page wp ON wr.wr_web_page_sk = wp.wp_web_page_sk
    JOIN customer_address ca_ref ON wr.wr_refunded_addr_sk = ca_ref.ca_address_sk
    JOIN customer_address ca_ret ON wr.wr_returning_addr_sk = ca_ret.ca_address_sk
    JOIN catalog_page cp ON cp.cp_start_date_sk = d_ret.d_date_sk
    WHERE d_ret.d_year = 2000
      AND wp.wp_image_count >= 3
      AND wp.wp_type = 'category'
      AND ca_ref.ca_state = 'CA'
      AND ca_ref.ca_zip IN ('40587', '75124')
      AND ca_ret.ca_city = 'Spring'
      AND cp.cp_department = 'Electronics'
      AND EXISTS (
          SELECT 1
          FROM promotion p
          JOIN date_dim d_pstart ON p.p_start_date_sk = d_pstart.d_date_sk
          JOIN date_dim d_pend   ON p.p_end_date_sk = d_pend.d_date_sk
          WHERE d_pstart.d_date_sk <= d_ret.d_date_sk
            AND d_pend.d_date_sk   >= d_ret.d_date_sk
            AND p.p_promo_name = 'Holiday Sale'
      )
    GROUP BY d_ret.d_year, d_ret.d_month_seq, wp.wp_type, cp.cp_department
)
SELECT
    d_year,
    d_month_seq,
    wp_type,
    cp_department,
    return_cnt,
    total_return_amt,
    avg_return_amt,
    total_fee,
    max_net_loss,
    min_net_loss,
    high_fee_total,
    low_fee_total,
    (SELECT MAX(p2.p_cost) FROM promotion p2 WHERE p2.p_promo_name = 'Holiday Sale') AS max_holiday_promo_cost,
    CASE WHEN total_fee > 1000 THEN 'High' ELSE 'Low' END AS fee_category,
    RANK() OVER (PARTITION BY d_year ORDER BY total_return_amt DESC) AS rank_by_month_total
FROM returns_agg
ORDER BY d_year, d_month_seq, rank_by_month_total
LIMIT 100
