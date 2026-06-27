/*
  Analytical query: Net profit per store, month, product category and customer demographic.
  It aggregates sales (store_sales) and returns (store_returns) for the year 2000,
  includes promotional costs, discounts and computes profit after returns and promotions.
*/
WITH sales_agg AS (
    SELECT
        s.s_store_id,
        d.d_year,
        d.d_month_seq,
        i.i_category,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(ss.ss_net_paid)               AS total_sales_net_paid,
        SUM(ss.ss_net_profit)             AS total_sales_net_profit,
        SUM(ss.ss_ext_discount_amt)       AS total_sales_discount,
        SUM(p.p_cost)                     AS total_promo_cost,
        COUNT(*)                          AS sales_txn_count
    FROM store_sales ss
    JOIN store s               ON ss.ss_store_sk   = s.s_store_sk
    JOIN date_dim d            ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i                ON ss.ss_item_sk   = i.i_item_sk
    JOIN promotion p           ON ss.ss_promo_sk  = p.p_promo_sk
    JOIN customer_demographics cd ON ss.ss_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_date >= DATE '2000-01-01'
      AND d.d_date <  DATE '2001-01-01'
    GROUP BY
        s.s_store_id,
        d.d_year,
        d.d_month_seq,
        i.i_category,
        cd.cd_gender,
        cd.cd_marital_status
),
returns_agg AS (
    SELECT
        s.s_store_id,
        d.d_year,
        d.d_month_seq,
        i.i_category,
        cd.cd_gender,
        cd.cd_marital_status,
        SUM(sr.sr_net_loss)       AS total_returns_net_loss,
        SUM(sr.sr_return_quantity) AS total_return_quantity,
        COUNT(*)                  AS return_txn_count
    FROM store_returns sr
    JOIN store s               ON sr.sr_store_sk   = s.s_store_sk
    JOIN date_dim d            ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i                ON sr.sr_item_sk   = i.i_item_sk
    JOIN customer_demographics cd ON sr.sr_cdemo_sk = cd.cd_demo_sk
    WHERE d.d_date >= DATE '2000-01-01'
      AND d.d_date <  DATE '2001-01-01'
    GROUP BY
        s.s_store_id,
        d.d_year,
        d.d_month_seq,
        i.i_category,
        cd.cd_gender,
        cd.cd_marital_status
)
SELECT
    COALESCE(s.s_store_id, r.s_store_id)               AS store_id,
    COALESCE(s.d_year, r.d_year)                       AS year,
    COALESCE(s.d_month_seq, r.d_month_seq)             AS month_seq,
    COALESCE(s.i_category, r.i_category)               AS category,
    COALESCE(s.cd_gender, r.cd_gender)                 AS gender,
    COALESCE(s.cd_marital_status, r.cd_marital_status) AS marital_status,
    COALESCE(s.total_sales_net_paid, 0)                AS total_sales_net_paid,
    COALESCE(s.total_sales_net_profit, 0)              AS total_sales_net_profit,
    COALESCE(s.total_sales_discount, 0)                AS total_sales_discount,
    COALESCE(s.total_promo_cost, 0)                    AS total_promo_cost,
    COALESCE(r.total_returns_net_loss, 0)              AS total_returns_net_loss,
    COALESCE(r.total_return_quantity, 0)               AS total_return_quantity,
    (COALESCE(s.total_sales_net_profit, 0) - COALESCE(r.total_returns_net_loss, 0)) AS net_profit_after_returns,
    (COALESCE(s.total_sales_net_profit, 0) - COALESCE(r.total_returns_net_loss, 0) - COALESCE(s.total_promo_cost, 0)) AS net_profit_after_returns_and_promos
FROM sales_agg s
FULL OUTER JOIN returns_agg r
    ON s.s_store_id        = r.s_store_id
   AND s.d_year            = r.d_year
   AND s.d_month_seq       = r.d_month_seq
   AND s.i_category        = r.i_category
   AND s.cd_gender         = r.cd_gender
   AND s.cd_marital_status = r.cd_marital_status
ORDER BY
    store_id,
    year,
    month_seq,
    category,
    gender,
    marital_status
