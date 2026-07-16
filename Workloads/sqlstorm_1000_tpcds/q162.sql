WITH
sales_combined AS (
    SELECT cs_sold_date_sk AS date_sk,
           cs_item_sk AS item_sk,
           cs_quantity AS quantity,
           cs_net_paid_inc_tax AS net_amount,
           cs_net_profit AS profit,
           cs_ext_discount_amt AS discount,
           'catalog' AS channel,
           cs_bill_cdemo_sk AS cdemo_sk
    FROM catalog_sales
    UNION ALL
    SELECT ss_sold_date_sk AS date_sk,
           ss_item_sk AS item_sk,
           ss_quantity AS quantity,
           ss_net_paid_inc_tax AS net_amount,
           ss_net_profit AS profit,
           ss_ext_discount_amt AS discount,
           'store' AS channel,
           ss_cdemo_sk AS cdemo_sk
    FROM store_sales
    UNION ALL
    SELECT ws_sold_date_sk AS date_sk,
           ws_item_sk AS item_sk,
           ws_quantity AS quantity,
           ws_net_paid_inc_tax AS net_amount,
           ws_net_profit AS profit,
           ws_ext_discount_amt AS discount,
           'web' AS channel,
           ws_bill_cdemo_sk AS cdemo_sk
    FROM web_sales
),
returns_combined AS (
    SELECT cr_returned_date_sk AS date_sk,
           cr_item_sk AS item_sk,
           cr_return_quantity AS quantity,
           cr_return_amt_inc_tax AS net_amount,
           cr_fee AS fee,
           'catalog' AS channel,
           cr_refunded_cdemo_sk AS cdemo_sk
    FROM catalog_returns
    UNION ALL
    SELECT sr_returned_date_sk AS date_sk,
           sr_item_sk AS item_sk,
           sr_return_quantity AS quantity,
           sr_return_amt_inc_tax AS net_amount,
           sr_fee AS fee,
           'store' AS channel,
           sr_cdemo_sk AS cdemo_sk
    FROM store_returns
    UNION ALL
    SELECT wr_returned_date_sk AS date_sk,
           wr_item_sk AS item_sk,
           wr_return_quantity AS quantity,
           wr_return_amt_inc_tax AS net_amount,
           wr_fee AS fee,
           'web' AS channel,
           wr_refunded_cdemo_sk AS cdemo_sk
    FROM web_returns
),
sales_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq AS month_seq,
        i.i_brand,
        i.i_category,
        cd.cd_gender,
        cd.cd_marital_status,
        s.channel,
        SUM(s.quantity) AS total_quantity_sold,
        SUM(s.net_amount) AS total_sales_amount,
        SUM(s.profit) AS total_profit,
        AVG(CASE WHEN s.discount > 0 THEN s.discount END) AS avg_discount
    FROM sales_combined s
    JOIN date_dim d ON s.date_sk = d.d_date_sk
    JOIN item i ON s.item_sk = i.i_item_sk
    JOIN customer_demographics cd ON s.cdemo_sk = cd.cd_demo_sk
    GROUP BY
        d.d_year,
        d.d_month_seq,
        i.i_brand,
        i.i_category,
        cd.cd_gender,
        cd.cd_marital_status,
        s.channel
),
returns_agg AS (
    SELECT
        d.d_year,
        d.d_month_seq AS month_seq,
        i.i_brand,
        i.i_category,
        cd.cd_gender,
        cd.cd_marital_status,
        r.channel,
        SUM(r.quantity) AS total_quantity_returned,
        SUM(r.net_amount) AS total_return_amount
    FROM returns_combined r
    JOIN date_dim d ON r.date_sk = d.d_date_sk
    JOIN item i ON r.item_sk = i.i_item_sk
    JOIN customer_demographics cd ON r.cdemo_sk = cd.cd_demo_sk
    GROUP BY
        d.d_year,
        d.d_month_seq,
        i.i_brand,
        i.i_category,
        cd.cd_gender,
        cd.cd_marital_status,
        r.channel
),
net_agg AS (
    SELECT
        sa.d_year,
        sa.month_seq,
        sa.i_brand,
        sa.i_category,
        sa.cd_gender,
        sa.cd_marital_status,
        sa.channel,
        sa.total_quantity_sold,
        sa.total_sales_amount,
        sa.total_profit,
        COALESCE(ra.total_quantity_returned, 0) AS total_quantity_returned,
        COALESCE(ra.total_return_amount, 0) AS total_return_amount,
        (sa.total_sales_amount - COALESCE(ra.total_return_amount, 0)) AS net_sales_amount,
        (sa.total_profit - COALESCE(ra.total_return_amount, 0) * 0.1) AS net_profit_adjusted,
        sa.avg_discount
    FROM sales_agg sa
    LEFT JOIN returns_agg ra
        ON sa.d_year = ra.d_year
        AND sa.month_seq = ra.month_seq
        AND sa.i_brand = ra.i_brand
        AND sa.i_category = ra.i_category
        AND sa.cd_gender = ra.cd_gender
        AND sa.cd_marital_status = ra.cd_marital_status
        AND sa.channel = ra.channel
),
net_with_mom AS (
    SELECT
        n.*,
        LAG(n.net_sales_amount) OVER (PARTITION BY n.i_brand, n.i_category, n.channel ORDER BY n.d_year, n.month_seq) AS prev_month_sales,
        (n.net_sales_amount - LAG(n.net_sales_amount) OVER (PARTITION BY n.i_brand, n.i_category, n.channel ORDER BY n.d_year, n.month_seq)) AS sales_mom
    FROM net_agg n
)
SELECT
    d_year,
    month_seq,
    i_brand,
    i_category,
    cd_gender,
    cd_marital_status,
    channel,
    total_quantity_sold,
    total_quantity_returned,
    total_sales_amount,
    total_return_amount,
    net_sales_amount,
    net_profit_adjusted,
    avg_discount,
    sales_mom
FROM net_with_mom
WHERE net_sales_amount > 0
ORDER BY d_year, month_seq, i_brand, i_category, channel, net_sales_amount DESC
LIMIT 100
