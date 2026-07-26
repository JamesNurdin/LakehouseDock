WITH daily_sales AS (
    SELECT
        ss.ss_store_sk,
        st.s_store_id,
        st.s_store_name,
        ss.ss_sold_date_sk AS date_key,
        SUM(ss.ss_net_profit) AS daily_profit,
        SUM(ss.ss_ext_sales_price) AS daily_sales
    FROM store_sales ss
    JOIN store st ON ss.ss_store_sk = st.s_store_sk
    GROUP BY ss.ss_store_sk, st.s_store_id, st.s_store_name, ss.ss_sold_date_sk
),
 daily_returns AS (
    SELECT
        ss.ss_store_sk,
        st.s_store_id,
        ss.ss_sold_date_sk AS date_key,
        SUM(cr.cr_net_loss) AS daily_return_loss,
        SUM(cr.cr_return_amount) AS daily_return_amount
    FROM catalog_returns cr
    JOIN customer_address ca ON cr.cr_refunded_addr_sk = ca.ca_address_sk
    JOIN store_sales ss ON ss.ss_addr_sk = ca.ca_address_sk
        AND ss.ss_sold_date_sk = cr.cr_returned_date_sk
    JOIN store st ON ss.ss_store_sk = st.s_store_sk
    GROUP BY ss.ss_store_sk, st.s_store_id, ss.ss_sold_date_sk
)
SELECT
    ds.date_key,
    ds.s_store_id,
    ds.s_store_name,
    ds.daily_profit,
    dr.daily_return_loss,
    ds.daily_profit - COALESCE(dr.daily_return_loss,0) AS net_profit_after_returns,
    LAG(ds.daily_profit) OVER (PARTITION BY ds.s_store_id ORDER BY ds.date_key) AS prev_day_profit,
    (ds.daily_profit - LAG(ds.daily_profit) OVER (PARTITION BY ds.s_store_id ORDER BY ds.date_key)) AS profit_change,
    PERCENT_RANK() OVER (PARTITION BY ds.date_key ORDER BY ds.daily_profit DESC) AS profit_percent_rank,
    CASE 
        WHEN ds.daily_profit > COALESCE(dr.daily_return_loss,0) THEN 'PROFIT_AFTER_RETURN'
        ELSE 'LOSS_AFTER_RETURN'
    END AS profit_vs_return_category,
    ROW_NUMBER() OVER (PARTITION BY ds.s_store_id ORDER BY ds.date_key DESC) AS recent_day_rank
FROM daily_sales ds
LEFT JOIN daily_returns dr 
    ON ds.s_store_id = dr.s_store_id AND ds.date_key = dr.date_key
ORDER BY ds.s_store_id, ds.date_key
