WITH sales_data AS (
    SELECT
        ss.ss_ticket_number,
        ss.ss_sold_date_sk,
        dd.d_date,
        ss.ss_store_sk,
        s.s_store_name,
        ss.ss_item_sk,
        i.i_item_id,
        i.i_category,
        ss.ss_quantity,
        ss.ss_net_paid_inc_tax,
        ss.ss_ext_sales_price,
        ss.ss_ext_discount_amt,
        ss.ss_net_profit,
        ss.ss_hdemo_sk,
        hd.hd_buy_potential,
        hd.hd_vehicle_count
    FROM store_sales ss
    JOIN date_dim dd ON ss.ss_sold_date_sk = dd.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN household_demographics hd ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    WHERE dd.d_year = 2020
      AND i.i_category = 'Sports'
      AND hd.hd_buy_potential = '1001-5000'
      AND ss.ss_quantity > 1
      AND ss.ss_net_paid_inc_tax > 100
      AND s.s_state = 'CA'
),
returns_data AS (
    SELECT
        sr.sr_ticket_number,
        sr.sr_returned_date_sk,
        dr.d_date AS return_date,
        sr.sr_store_sk,
        s2.s_store_name,
        sr.sr_item_sk,
        i2.i_item_id,
        i2.i_category,
        sr.sr_return_quantity,
        sr.sr_return_amt_inc_tax,
        r.r_reason_desc,
        sr.sr_hdemo_sk,
        hd2.hd_buy_potential
    FROM store_returns sr
    JOIN date_dim dr ON sr.sr_returned_date_sk = dr.d_date_sk
    JOIN item i2 ON sr.sr_item_sk = i2.i_item_sk
    JOIN household_demographics hd2 ON sr.sr_hdemo_sk = hd2.hd_demo_sk
    JOIN store s2 ON sr.sr_store_sk = s2.s_store_sk
    JOIN reason r ON sr.sr_reason_sk = r.r_reason_sk
    WHERE dr.d_year = 2020
      AND i2.i_category = 'Sports'
      AND hd2.hd_vehicle_count >= 1
      AND sr.sr_return_quantity > 0
      AND sr.sr_return_amt_inc_tax > 50
      AND s2.s_state = 'CA'
),
union_agg AS (
    SELECT
        sd.ss_store_sk AS store_key,
        s.s_store_name,
        SUM(sd.ss_net_paid_inc_tax) AS total_sales,
        COUNT(*) AS sales_txn_count
    FROM sales_data sd
    JOIN store s ON sd.ss_store_sk = s.s_store_sk
    GROUP BY sd.ss_store_sk, s.s_store_name
    UNION
    SELECT
        rd.sr_store_sk AS store_key,
        s3.s_store_name,
        -SUM(rd.sr_return_amt_inc_tax) AS total_sales,
        COUNT(*) AS sales_txn_count
    FROM returns_data rd
    JOIN store s3 ON rd.sr_store_sk = s3.s_store_sk
    GROUP BY rd.sr_store_sk, s3.s_store_name
),
closed_store_keys AS (
    SELECT s_closed.s_store_sk AS store_key
    FROM store s_closed
    JOIN date_dim d_closed ON s_closed.s_closed_date_sk = d_closed.d_date_sk
    WHERE d_closed.d_year < 2020
),
high_profit_store_keys AS (
    SELECT sd2.ss_store_sk AS store_key
    FROM sales_data sd2
    WHERE sd2.ss_net_profit > 500
    GROUP BY sd2.ss_store_sk
),
filtered_keys AS (
    SELECT ua.store_key
    FROM union_agg ua
    EXCEPT
    SELECT cs.store_key FROM closed_store_keys cs
    INTERSECT
    SELECT hp.store_key FROM high_profit_store_keys hp
),
final_data AS (
    SELECT
        ua.store_key,
        ua.s_store_name,
        ua.total_sales,
        ua.sales_txn_count,
        RANK() OVER (ORDER BY ua.total_sales DESC) AS sales_rank,
        (
            SELECT SUM(sr2.sr_return_amt_inc_tax)
            FROM store_returns sr2
            WHERE sr2.sr_store_sk = ua.store_key
              AND sr2.sr_returned_date_sk = (
                  SELECT MAX(d2.d_date_sk)
                  FROM date_dim d2
                  WHERE d2.d_year = 2020
              )
        ) AS recent_return_total
    FROM union_agg ua
    JOIN filtered_keys fk ON ua.store_key = fk.store_key
)
SELECT
    store_key,
    s_store_name,
    total_sales,
    sales_txn_count,
    sales_rank,
    recent_return_total
FROM final_data
ORDER BY sales_rank
LIMIT 100
