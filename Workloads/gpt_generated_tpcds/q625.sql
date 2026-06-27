WITH sales_data AS (
    SELECT
        ss.ss_store_sk AS store_sk,
        s.s_store_name AS store_name,
        d.d_year,
        d.d_month_seq,
        date_format(d.d_date, '%Y-%m') AS year_month,
        i.i_category,
        i.i_class,
        i.i_brand,
        SUM(ss.ss_ext_sales_price) AS total_sales,
        SUM(ss.ss_ext_discount_amt) AS total_discount,
        SUM(ss.ss_net_profit) AS total_profit,
        COUNT(DISTINCT ss.ss_ticket_number) AS num_transactions
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN store s ON ss.ss_store_sk = s.s_store_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    JOIN promotion p ON ss.ss_promo_sk = p.p_promo_sk
    WHERE p.p_discount_active = 'Y'
      AND d.d_date >= DATE '2022-01-01' AND d.d_date < DATE '2023-01-01'
    GROUP BY
        ss.ss_store_sk,
        s.s_store_name,
        d.d_year,
        d.d_month_seq,
        date_format(d.d_date, '%Y-%m'),
        i.i_category,
        i.i_class,
        i.i_brand
),
returns_data AS (
    SELECT
        sr.sr_store_sk AS store_sk,
        s.s_store_name AS store_name,
        d.d_year,
        d.d_month_seq,
        date_format(d.d_date, '%Y-%m') AS year_month,
        i.i_category,
        i.i_class,
        i.i_brand,
        SUM(sr.sr_return_amt) AS total_return_amount,
        SUM(sr.sr_refunded_cash) AS total_refunded_cash,
        SUM(sr.sr_store_credit) AS total_store_credit,
        SUM(sr.sr_net_loss) AS total_net_loss,
        COUNT(DISTINCT sr.sr_ticket_number) AS num_returns
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN store s ON sr.sr_store_sk = s.s_store_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    GROUP BY
        sr.sr_store_sk,
        s.s_store_name,
        d.d_year,
        d.d_month_seq,
        date_format(d.d_date, '%Y-%m'),
        i.i_category,
        i.i_class,
        i.i_brand
)
SELECT
    sd.store_name,
    sd.year_month,
    sd.i_category,
    sd.i_class,
    sd.i_brand,
    sd.total_sales,
    sd.total_discount,
    CASE WHEN sd.total_sales = 0 THEN 0 ELSE sd.total_discount / sd.total_sales END AS discount_rate,
    sd.total_profit,
    COALESCE(rd.total_return_amount, 0) AS total_return_amount,
    COALESCE(rd.total_refunded_cash, 0) AS total_refunded_cash,
    COALESCE(rd.total_store_credit, 0) AS total_store_credit,
    COALESCE(rd.total_net_loss, 0) AS total_net_loss,
    sd.total_profit - COALESCE(rd.total_refunded_cash, 0) - COALESCE(rd.total_store_credit, 0) - COALESCE(rd.total_net_loss, 0) AS net_profit_after_returns,
    sd.num_transactions,
    COALESCE(rd.num_returns, 0) AS num_returns
FROM sales_data sd
LEFT JOIN returns_data rd
    ON sd.store_sk = rd.store_sk
   AND sd.year_month = rd.year_month
   AND sd.i_category = rd.i_category
   AND sd.i_class = rd.i_class
   AND sd.i_brand = rd.i_brand
ORDER BY
    sd.store_name,
    sd.year_month,
    sd.i_category,
    sd.i_class,
    sd.i_brand
