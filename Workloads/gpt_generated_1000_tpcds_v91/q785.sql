WITH base_sales AS (
    SELECT
        ss.ss_sold_date_sk,
        ss.ss_sold_time_sk,
        ss.ss_item_sk,
        ss.ss_customer_sk,
        ss.ss_cdemo_sk,
        ss.ss_store_sk,
        ss.ss_promo_sk,
        ss.ss_ticket_number,
        ss.ss_quantity,
        ss.ss_sales_price,
        ss.ss_ext_sales_price,
        ss.ss_net_paid,
        ss.ss_net_profit,
        td.t_time_sk AS sold_time_sk,
        td.t_hour,
        td.t_minute,
        cd.cd_demo_sk,
        cd.cd_gender,
        cd.cd_credit_rating,
        cd.cd_dep_college_count,
        st.s_store_sk,
        st.s_store_name,
        st.s_state,
        st.s_city,
        p.p_promo_sk,
        p.p_promo_name,
        p.p_discount_active,
        ARRAY[st.s_state, st.s_city] AS loc_array
    FROM store_sales ss
    TABLESAMPLE BERNOULLI (10)
    JOIN time_dim td
        ON ss.ss_sold_time_sk = td.t_time_sk
    JOIN customer_demographics cd
        ON ss.ss_cdemo_sk = cd.cd_demo_sk
    JOIN store st
        ON ss.ss_store_sk = st.s_store_sk
    JOIN promotion p
        ON ss.ss_promo_sk = p.p_promo_sk
),
sales_details AS (
    SELECT
        bs.*,
        sr.sr_return_quantity,
        sr.sr_return_amt,
        sr.sr_net_loss AS sr_net_loss,
        cr.cr_net_loss AS cr_net_loss,
        w.w_warehouse_name,
        ROW_NUMBER() OVER (PARTITION BY bs.s_store_sk ORDER BY bs.ss_net_profit DESC) AS rn_by_store
    FROM base_sales bs
    LEFT JOIN store_returns sr
        ON sr.sr_item_sk = bs.ss_item_sk
       AND sr.sr_ticket_number = bs.ss_ticket_number
       AND sr.sr_store_sk = bs.s_store_sk
       AND sr.sr_cdemo_sk = bs.cd_demo_sk
    LEFT JOIN time_dim td_ret
        ON sr.sr_return_time_sk = td_ret.t_time_sk
    LEFT JOIN catalog_returns cr
        ON cr.cr_returned_time_sk = bs.sold_time_sk
       AND cr.cr_refunded_cdemo_sk = bs.cd_demo_sk
       AND cr.cr_returning_cdemo_sk = bs.cd_demo_sk
    LEFT JOIN warehouse w
        ON cr.cr_warehouse_sk = w.w_warehouse_sk
    WHERE bs.s_state = 'CA'
      AND bs.cd_credit_rating = 'Good'
      AND bs.p_discount_active = 'Y'
      AND bs.ss_sold_date_sk BETWEEN 2450815 AND 2450825
      AND (sr.sr_return_quantity IS NULL OR sr.sr_return_quantity > 0)
      AND NOT EXISTS (
            SELECT 1
            FROM reason r_ex
            WHERE r_ex.r_reason_sk = sr.sr_reason_sk
              AND r_ex.r_reason_desc = 'Damaged Goods'
      )
      AND EXISTS (
            SELECT 1
            FROM reason r_in
            WHERE r_in.r_reason_sk = sr.sr_reason_sk
      )
),
expanded AS (
    SELECT
        sd.*,
        loc
    FROM sales_details sd
    CROSS JOIN UNNEST(sd.loc_array) AS t(loc)
),
cube_agg AS (
    SELECT
        s_state,
        cd_gender,
        p_promo_name,
        s_store_name,
        SUM(ss_net_profit) AS total_net_profit,
        SUM(ss_ext_sales_price) AS total_sales,
        COUNT(*) AS transaction_count
    FROM expanded
    GROUP BY CUBE (s_state, cd_gender, p_promo_name, s_store_name)
)
SELECT
    s_state,
    cd_gender,
    p_promo_name,
    s_store_name,
    total_net_profit,
    total_sales,
    transaction_count,
    total_net_profit / NULLIF(transaction_count, 0) AS avg_profit_per_txn
FROM cube_agg
WHERE total_sales > 10000
  AND transaction_count >= 5
ORDER BY total_net_profit DESC
LIMIT 100
