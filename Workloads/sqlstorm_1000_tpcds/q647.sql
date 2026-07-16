WITH sales_union AS (
    SELECT
        d.d_year,
        d.d_moy,
        i.i_category,
        ss.ss_store_sk AS location_sk,
        ss.ss_promo_sk AS promo_sk,
        ss.ss_net_paid AS net_paid,
        ss.ss_net_profit AS net_profit,
        ss.ss_ext_discount_amt AS discount_amount,
        'store' AS sales_channel
    FROM store_sales ss
    JOIN date_dim d ON ss.ss_sold_date_sk = d.d_date_sk
    JOIN item i ON ss.ss_item_sk = i.i_item_sk
    UNION ALL
    SELECT
        d.d_year,
        d.d_moy,
        i.i_category,
        cs.cs_warehouse_sk AS location_sk,
        cs.cs_promo_sk AS promo_sk,
        cs.cs_net_paid AS net_paid,
        cs.cs_net_profit AS net_profit,
        cs.cs_ext_discount_amt AS discount_amount,
        'catalog' AS sales_channel
    FROM catalog_sales cs
    JOIN date_dim d ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN item i ON cs.cs_item_sk = i.i_item_sk
    UNION ALL
    SELECT
        d.d_year,
        d.d_moy,
        i.i_category,
        ws.ws_warehouse_sk AS location_sk,
        ws.ws_promo_sk AS promo_sk,
        ws.ws_net_paid AS net_paid,
        ws.ws_net_profit AS net_profit,
        ws.ws_ext_discount_amt AS discount_amount,
        'web' AS sales_channel
    FROM web_sales ws
    JOIN date_dim d ON ws.ws_sold_date_sk = d.d_date_sk
    JOIN item i ON ws.ws_item_sk = i.i_item_sk
),
sales_agg AS (
    SELECT
        d_year,
        d_moy,
        i_category,
        sales_channel,
        sum(net_paid) AS total_net_paid,
        sum(net_profit) AS total_net_profit,
        sum(discount_amount) AS total_discount_amount,
        sum(p.p_cost) AS total_promo_cost
    FROM sales_union su
    LEFT JOIN promotion p ON su.promo_sk = p.p_promo_sk
    GROUP BY d_year, d_moy, i_category, sales_channel
),
returns_union AS (
    SELECT
        d.d_year,
        d.d_moy,
        i.i_category,
        'store' AS return_channel,
        sr.sr_net_loss AS net_loss
    FROM store_returns sr
    JOIN date_dim d ON sr.sr_returned_date_sk = d.d_date_sk
    JOIN item i ON sr.sr_item_sk = i.i_item_sk
    UNION ALL
    SELECT
        d.d_year,
        d.d_moy,
        i.i_category,
        'catalog' AS return_channel,
        cr.cr_net_loss AS net_loss
    FROM catalog_returns cr
    JOIN date_dim d ON cr.cr_returned_date_sk = d.d_date_sk
    JOIN item i ON cr.cr_item_sk = i.i_item_sk
    UNION ALL
    SELECT
        d.d_year,
        d.d_moy,
        i.i_category,
        'web' AS return_channel,
        wr.wr_net_loss AS net_loss
    FROM web_returns wr
    JOIN date_dim d ON wr.wr_returned_date_sk = d.d_date_sk
    JOIN item i ON wr.wr_item_sk = i.i_item_sk
),
returns_agg AS (
    SELECT
        d_year,
        d_moy,
        i_category,
        sum(net_loss) AS total_net_loss
    FROM returns_union
    GROUP BY d_year, d_moy, i_category
),
final AS (
    SELECT
        s.d_year,
        s.d_moy,
        s.i_category,
        s.sales_channel,
        s.total_net_paid,
        s.total_net_profit,
        s.total_discount_amount,
        s.total_promo_cost,
        coalesce(r.total_net_loss, 0) AS total_net_loss,
        (s.total_net_paid - coalesce(r.total_net_loss, 0)) AS net_sales_ex_returns,
        (s.total_net_profit - coalesce(r.total_net_loss, 0)) AS net_profit_ex_returns,
        row_number() OVER (PARTITION BY s.d_year, s.d_moy ORDER BY (s.total_net_profit - coalesce(r.total_net_loss, 0)) DESC) AS profit_rank_by_channel
    FROM sales_agg s
    LEFT JOIN returns_agg r
        ON s.d_year = r.d_year AND s.d_moy = r.d_moy AND s.i_category = r.i_category
)
SELECT
    d_year,
    d_moy,
    i_category,
    sales_channel,
    total_net_paid,
    total_net_profit,
    total_discount_amount,
    total_promo_cost,
    total_net_loss,
    net_sales_ex_returns,
    net_profit_ex_returns,
    profit_rank_by_channel
FROM final
WHERE d_year = 2001
ORDER BY d_year, d_moy, profit_rank_by_channel
LIMIT 100
