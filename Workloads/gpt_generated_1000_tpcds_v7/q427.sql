WITH base AS (
    SELECT
        d.d_year,
        hd.hd_buy_potential,
        cs.cs_order_number,
        cs.cs_ext_sales_price AS catalog_sales_amt,
        ss.ss_net_paid AS store_sales_paid,
        wr.wr_net_loss AS web_return_loss,
        cs.cs_net_profit AS catalog_profit,
        ss.ss_net_profit AS store_profit,
        cs.cs_quantity,
        ss.ss_quantity AS store_quantity,
        wp.wp_type
    FROM catalog_sales cs
    JOIN date_dim d
        ON cs.cs_sold_date_sk = d.d_date_sk
    JOIN household_demographics hd
        ON cs.cs_bill_hdemo_sk = hd.hd_demo_sk
    JOIN store_sales ss
        ON ss.ss_hdemo_sk = hd.hd_demo_sk
    JOIN web_page wp
        ON wp.wp_creation_date_sk = d.d_date_sk
    JOIN web_returns wr
        ON wr.wr_web_page_sk = wp.wp_web_page_sk
    WHERE d.d_year = 2002
      AND d.d_current_year = 'Y'
      AND hd.hd_vehicle_count >= 2
      AND cs.cs_quantity >= 2
      AND wp.wp_type = 'content'
      AND ss.ss_sales_price > 10.00
),
agg AS (
    SELECT
        base.d_year,
        base.hd_buy_potential,
        SUM(base.catalog_sales_amt) AS total_catalog_sales,
        SUM(base.store_sales_paid) AS total_store_sales,
        SUM(base.web_return_loss) AS total_return_loss,
        SUM(base.catalog_profit + base.store_profit) AS total_profit,
        COUNT(DISTINCT base.cs_order_number) AS distinct_orders
    FROM base
    GROUP BY base.d_year, base.hd_buy_potential
)
SELECT
    agg.hd_buy_potential,
    AVG(agg.total_profit) AS avg_total_profit,
    SUM(agg.distinct_orders) AS total_orders
FROM agg
GROUP BY agg.hd_buy_potential
HAVING AVG(agg.total_profit) > 1000
